require 'rails_helper'

RSpec.describe "Spreadsheets", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:member_user) { create(:user, :member) }
  let(:spreadsheet) { create(:spreadsheet) }

  describe "GET /spreadsheets" do
    context "when logged in as admin" do
      before { login_as(admin_user) }

      it "returns success" do
        get spreadsheets_path
        expect(response).to have_http_status(:success)
      end

      it "displays all spreadsheets" do
        spreadsheet1 = create(:spreadsheet, name: "Test Sheet 1")
        spreadsheet2 = create(:spreadsheet, name: "Test Sheet 2")

        get spreadsheets_path
        expect(response.body).to include("Test Sheet 1")
        expect(response.body).to include("Test Sheet 2")
      end
    end

    context "when logged in as member" do
      before { login_as(member_user) }

      it "returns success" do
        get spreadsheets_path
        expect(response).to have_http_status(:success)
      end

      it "displays only permitted spreadsheets" do
        permitted_sheet = create(:spreadsheet, name: "Permitted")
        not_permitted = create(:spreadsheet, name: "Not Permitted")
        create(:user_spreadsheet_permission, user: member_user, spreadsheet: permitted_sheet)

        get spreadsheets_path
        expect(response.body).to include("Permitted")
        expect(response.body).not_to include("Not Permitted")
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get spreadsheets_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /spreadsheets/:id" do
    context "when logged in as admin" do
      before { login_as(admin_user) }

      it "returns success" do
        get spreadsheet_path(spreadsheet)
        expect(response).to have_http_status(:success)
      end

      it "displays spreadsheet details" do
        spreadsheet.update(name: "Detail Test", description: "Test Description")
        get spreadsheet_path(spreadsheet)
        expect(response.body).to include("Detail Test")
        expect(response.body).to include("Test Description")
      end
    end

    context "when logged in as member without permission" do
      before { login_as(member_user) }

      it "redirects with alert" do
        get spreadsheet_path(spreadsheet)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("このスプレッドシートへのアクセス権限がありません")
      end
    end

    context "when logged in as member with permission" do
      before do
        login_as(member_user)
        create(:user_spreadsheet_permission, user: member_user, spreadsheet: spreadsheet)
      end

      it "returns success" do
        get spreadsheet_path(spreadsheet)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /spreadsheets" do
    let(:valid_params) do
      {
        spreadsheet: {
          name: "New Spreadsheet",
          spreadsheet_id: "test_id_123",
          description: "Test description"
        }
      }
    end

    let(:mock_client) { instance_double(GoogleSheetsClient) }
    let(:mock_google_spreadsheet) { 
      double('Spreadsheet', 
        properties: double(title: 'Google Title'),
        sheets: [
          double('Sheet', properties: double(title: 'Sheet1', sheet_id: 1)),
          double('Sheet', properties: double(title: 'Sheet2', sheet_id: 2))
        ]
      )
    }

    before do
      allow(GoogleSheetsClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:get_spreadsheet).and_return(mock_google_spreadsheet)
    end

    context "when logged in as admin" do
      before { login_as(admin_user) }

      it "creates a new spreadsheet" do
        expect {
          post spreadsheets_path, params: valid_params
        }.to change(Spreadsheet, :count).by(1)

        expect(response).to redirect_to(spreadsheet_path(Spreadsheet.last))
        expect(flash[:notice]).to eq("スプレッドシートを登録しました")
      end

      context "when name is blank" do
        it "uses title from Google Sheets" do
          valid_params[:spreadsheet][:name] = ""
          post spreadsheets_path, params: valid_params

          expect(Spreadsheet.last.name).to eq("Google Title")
        end
      end

      context "when spreadsheet_id not found" do
        before do
          allow(mock_client).to receive(:get_spreadsheet).and_raise(Google::Apis::ClientError.new('Not found'))
        end

        it "does not create spreadsheet and shows error" do
          expect {
            post spreadsheets_path, params: valid_params
          }.not_to change(Spreadsheet, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(flash[:alert]).to include("指定されたスプレッドシートIDが見つかりません")
        end
      end
    end

    context "when logged in as member" do
      before { login_as(member_user) }

      it "redirects with alert" do
        post spreadsheets_path, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("管理者権限が必要です")
      end
    end
  end

  describe "DELETE /spreadsheets/:id" do
    before { spreadsheet }

    context "when logged in as admin" do
      before { login_as(admin_user) }

      it "deletes the spreadsheet" do
        expect {
          delete spreadsheet_path(spreadsheet)
        }.to change(Spreadsheet, :count).by(-1)

        expect(response).to redirect_to(spreadsheets_path)
        expect(flash[:notice]).to eq("スプレッドシートを削除しました")
      end
    end

    context "when logged in as member" do
      before { login_as(member_user) }

      it "redirects with alert" do
        delete spreadsheet_path(spreadsheet)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("管理者権限が必要です")
      end
    end
  end
end
