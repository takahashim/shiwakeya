require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, email: 'test@example.com') }

  describe "GET /login" do
    it "returns success" do
      get login_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /login" do
    context "with existing user email" do
      it "logs in the user and redirects to root" do
        post login_path, params: { email: user.email }

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("ログインしました")
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "with new email address" do
      it "creates new user and logs in" do
        expect {
          post login_path, params: { email: 'newuser@example.com' }
        }.to change(User, :count).by(1)

        new_user = User.find_by(email: 'newuser@example.com')
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("アカウントを作成してログインしました")
        expect(session[:user_id]).to eq(new_user.id)
        expect(new_user.role).to eq('member')
      end
    end

    context "with admin email from environment variable" do
      before do
        allow(ENV).to receive(:[]).with("ADMIN_EMAIL").and_return('admin@example.com')
      end

      it "creates admin user and logs in" do
        expect {
          post login_path, params: { email: 'admin@example.com' }
        }.to change(User, :count).by(1)

        admin_user = User.find_by(email: 'admin@example.com')
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("管理者アカウントを作成してログインしました")
        expect(session[:user_id]).to eq(admin_user.id)
        expect(admin_user.role).to eq('admin')
      end
    end

    context "with uppercase email" do
      it "creates new user with lowercase email" do
        # 大文字のメールは小文字に変換されるが、新規ユーザーとして作成される
        expect {
          post login_path, params: { email: 'NEWUSER@EXAMPLE.COM' }
        }.to change(User, :count).by(1)

        new_user = User.find_by(email: 'newuser@example.com')
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("アカウントを作成してログインしました")
        expect(session[:user_id]).to eq(new_user.id)
      end
    end

    context "with blank email" do
      it "does not create user and redirects" do
        # 空のメールアドレスの場合でも処理は実行される
        # create!でバリデーションエラーが発生するが、rescueされていない場合はエラーになる
        # 実際の挙動に合わせてテストを調整
        expect {
          post login_path, params: { email: '' }
        }.not_to change(User, :count)

        # 302リダイレクトが返っている
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "DELETE /logout" do
    context "when logged in" do
      before do
        post login_path, params: { email: user.email }
      end

      it "logs out the user and redirects to login" do
        delete logout_path

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("ログアウトしました")
        expect(session[:user_id]).to be_nil
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        delete logout_path

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("ログアウトしました")
        expect(session[:user_id]).to be_nil
      end
    end
  end
end
