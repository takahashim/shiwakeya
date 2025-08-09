require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#can_access_spreadsheet?' do
    let(:spreadsheet) { create(:spreadsheet) }

    context 'when user is admin' do
      let(:user) { create(:user, :admin) }

      it 'returns true for any spreadsheet' do
        expect(user.can_access_spreadsheet?(spreadsheet)).to be true
      end
    end

    context 'when user is accountant' do
      let(:user) { create(:user, :accountant) }

      it 'returns true for any spreadsheet' do
        expect(user.can_access_spreadsheet?(spreadsheet)).to be true
      end
    end

    context 'when user is member' do
      let(:user) { create(:user, :member) }

      context 'with permission' do
        before do
          create(:user_spreadsheet_permission, user: user, spreadsheet: spreadsheet)
        end

        it 'returns true' do
          expect(user.can_access_spreadsheet?(spreadsheet)).to be true
        end
      end

      context 'without permission' do
        it 'returns false' do
          expect(user.can_access_spreadsheet?(spreadsheet)).to be false
        end
      end

      context 'when spreadsheet is nil' do
        it 'returns false' do
          expect(user.can_access_spreadsheet?(nil)).to be false
        end
      end
    end
  end

  describe '#accessible_spreadsheets' do
    let!(:spreadsheet1) { create(:spreadsheet) }
    let!(:spreadsheet2) { create(:spreadsheet) }
    let!(:spreadsheet3) { create(:spreadsheet) }

    context 'when user is admin' do
      let(:user) { create(:user, :admin) }

      it 'returns all spreadsheets' do
        expect(user.accessible_spreadsheets).to match_array([ spreadsheet1, spreadsheet2, spreadsheet3 ])
      end
    end

    context 'when user is accountant' do
      let(:user) { create(:user, :accountant) }

      it 'returns all spreadsheets' do
        expect(user.accessible_spreadsheets).to match_array([ spreadsheet1, spreadsheet2, spreadsheet3 ])
      end
    end

    context 'when user is member' do
      let(:user) { create(:user, :member) }

      before do
        create(:user_spreadsheet_permission, user: user, spreadsheet: spreadsheet1)
        create(:user_spreadsheet_permission, user: user, spreadsheet: spreadsheet3)
      end

      it 'returns only permitted spreadsheets' do
        expect(user.accessible_spreadsheets).to match_array([ spreadsheet1, spreadsheet3 ])
      end
    end
  end
end
