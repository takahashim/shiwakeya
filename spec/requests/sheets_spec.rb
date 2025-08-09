require 'rails_helper'

RSpec.describe "Sheets", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:member_user) { create(:user, :member) }
  let(:spreadsheet) { create(:spreadsheet) }
  let(:sheet) { create(:sheet, spreadsheet: spreadsheet) }

  describe "GET /spreadsheets/:spreadsheet_id/sheets/:id" do
    context "when logged in with access" do
      before { login_as(admin_user) }

      it "returns success" do
        get spreadsheet_sheet_path(spreadsheet, sheet)
        expect(response).to have_http_status(:success)
      end

      it "displays sheet data" do
        sheet.update(sheet_name: "Test Sheet", data: '[["Header1", "Header2"], ["Data1", "Data2"]]')
        get spreadsheet_sheet_path(spreadsheet, sheet)
        expect(response.body).to include("Test Sheet")
        expect(response.body).to include("Header1")
        expect(response.body).to include("Data1")
      end

      context "when sheet has no data" do
        it "displays no data message" do
          sheet.update(data: nil)
          get spreadsheet_sheet_path(spreadsheet, sheet)
          expect(response.body).to include("データがありません")
        end
      end
    end

    context "when logged in without access" do
      before { login_as(member_user) }

      it "redirects with alert" do
        get spreadsheet_sheet_path(spreadsheet, sheet)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("このスプレッドシートへのアクセス権限がありません")
      end
    end
  end

  describe "POST /spreadsheets/:spreadsheet_id/sheets/:sheet_id/sync" do
    let(:mock_values) { [ [ "New Data" ] ] }

    before do
      allow_any_instance_of(Spreadsheet).to receive(:fetch_sheet_data).and_return(mock_values)
    end

    context "when logged in with access" do
      before { login_as(admin_user) }

      it "syncs sheet data and redirects" do
        post spreadsheet_sheet_sync_path(spreadsheet, sheet)

        expect(response).to redirect_to(spreadsheet_sheet_path(spreadsheet, sheet))
        expect(flash[:notice]).to eq("データを同期しました")

        sheet.reload
        expect(sheet.data).to eq(mock_values.to_json)
      end
    end

    context "when logged in without access" do
      before { login_as(member_user) }

      it "redirects with alert" do
        post spreadsheet_sheet_sync_path(spreadsheet, sheet)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("このスプレッドシートへのアクセス権限がありません")
      end
    end

    context "when sync fails" do
      before do
        login_as(admin_user)
        allow_any_instance_of(Spreadsheet).to receive(:fetch_sheet_data).and_raise(StandardError.new("API Error"))
      end

      it "redirects with error message" do
        # ApplicationControllerのrescue_fromでエラーがキャッチされる
        post spreadsheet_sheet_sync_path(spreadsheet, sheet)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("エラーが発生しました")
      end
    end
  end

  describe "POST /spreadsheets/:spreadsheet_id/sheets/:sheet_id/append" do
    let(:mock_client) { instance_double(GoogleSheetsClient) }
    let(:row_params) do
      {
        row_data: {
          col0: "Value1",
          col1: "Value2"
        }
      }
    end

    before do
      allow(GoogleSheetsClient).to receive(:new).and_return(mock_client)
    end

    context "when logged in with access" do
      before { login_as(admin_user) }

      context "when append is successful" do
        before do
          allow(mock_client).to receive(:append_values).and_return(true)
        end

        it "appends row and redirects" do
          post spreadsheet_sheet_append_path(spreadsheet, sheet), params: row_params

          expect(response).to redirect_to(spreadsheet_sheet_path(spreadsheet, sheet))
          expect(flash[:notice]).to eq("行を追加しました")
        end
      end

      context "when append fails" do
        before do
          allow(mock_client).to receive(:append_values).and_return(nil)
        end

        it "redirects with error" do
          post spreadsheet_sheet_append_path(spreadsheet, sheet), params: row_params

          expect(response).to redirect_to(spreadsheet_sheet_path(spreadsheet, sheet))
          expect(flash[:alert]).to eq("行の追加に失敗しました")
        end
      end

      context "when no data provided" do
        it "redirects with error" do
          post spreadsheet_sheet_append_path(spreadsheet, sheet), params: {}

          expect(response).to redirect_to(spreadsheet_sheet_path(spreadsheet, sheet))
          expect(flash[:alert]).to eq("データが送信されていません")
        end
      end
    end

    context "when logged in without access" do
      before { login_as(member_user) }

      it "redirects with alert" do
        post spreadsheet_sheet_append_path(spreadsheet, sheet), params: row_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("このスプレッドシートへのアクセス権限がありません")
      end
    end
  end

  describe "DELETE /spreadsheets/:spreadsheet_id/sheets/:sheet_id/clear" do
    context "when logged in as admin" do
      before { login_as(admin_user) }

      it "clears local data and redirects" do
        sheet.update(data: '[["Data"]]', last_synced_at: Time.current)

        delete spreadsheet_sheet_clear_path(spreadsheet, sheet)

        expect(response).to redirect_to(spreadsheet_sheet_path(spreadsheet, sheet))
        expect(flash[:notice]).to eq("データをクリアしました")

        sheet.reload
        expect(sheet.data).to be_nil
        expect(sheet.last_synced_at).to be_nil
      end

      context "when clear fails" do
        before do
          allow_any_instance_of(Sheet).to receive(:clear_local_data).and_raise(StandardError.new("Error"))
        end

        it "redirects with error" do
          delete spreadsheet_sheet_clear_path(spreadsheet, sheet)

          expect(response).to redirect_to(spreadsheet_sheet_path(spreadsheet, sheet))
          expect(flash[:alert]).to include("データのクリアに失敗しました")
        end
      end
    end

    context "when logged in as member" do
      before { login_as(member_user) }

      it "redirects with alert" do
        delete spreadsheet_sheet_clear_path(spreadsheet, sheet)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("管理者権限が必要です")
      end
    end
  end

  describe "PUT /spreadsheets/:spreadsheet_id/sheets/:id" do
    let(:update_params) do
      {
        data: '[["Updated1", "Updated2"]]'
      }
    end

    context "when logged in with access" do
      before { login_as(admin_user) }

      context "when update is successful" do
        before do
          allow_any_instance_of(Sheet).to receive(:write_data).and_return(true)
        end

        it "updates data and redirects" do
          put spreadsheet_sheet_path(spreadsheet, sheet), params: update_params

          expect(response).to redirect_to(spreadsheet_sheet_path(spreadsheet, sheet))
          expect(flash[:notice]).to eq("データを更新しました")
        end
      end

      context "when update fails" do
        before do
          allow_any_instance_of(Sheet).to receive(:write_data).and_return(false)
        end

        it "redirects with error" do
          put spreadsheet_sheet_path(spreadsheet, sheet), params: update_params

          expect(response).to redirect_to(spreadsheet_sheet_path(spreadsheet, sheet))
          expect(flash[:alert]).to eq("データの更新に失敗しました")
        end
      end

      context "when no data provided" do
        it "redirects with error" do
          put spreadsheet_sheet_path(spreadsheet, sheet), params: {}

          expect(response).to redirect_to(spreadsheet_sheet_path(spreadsheet, sheet))
          expect(flash[:alert]).to eq("データが送信されていません")
        end
      end
    end

    context "when logged in without access" do
      before { login_as(member_user) }

      it "redirects with alert" do
        put spreadsheet_sheet_path(spreadsheet, sheet), params: update_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("このスプレッドシートへのアクセス権限がありません")
      end
    end
  end
end
