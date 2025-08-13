class SpreadsheetSync < ApplicationRecord
  before_create :set_uuid, if: -> { uuid.blank? }

  enum :sync_status, {
    pending: 0,
    synced: 1,
    conflict: 2,
    error: 3
  }

  validates :uuid, presence: true, uniqueness: true
  validates :sheet_id, presence: true
  validates :sheet_id, uniqueness: { scope: :row_number }, if: :row_number?

  serialize :sheet_data, coder: JSON
  serialize :local_data, coder: JSON

  scope :needs_sync, -> { where(sync_status: [ :pending, :conflict ]) }
  scope :by_sheet, ->(sheet_id) { where(sheet_id: sheet_id) }

  def self.generate_uuidv7
    Uuidv7Generator.generate
  end

  def mark_synced!
    update!(
      sync_status: :synced,
      last_synced_at: Time.current,
      version: version + 1
    )
  end

  def detect_conflict(sheet_timestamp)
    return false if sheet_modified_at.nil?
    sheet_timestamp > sheet_modified_at && local_data_changed?
  end

  def local_data_changed?
    saved_change_to_local_data? || local_data_changed?
  end

  def merge_sheet_data(new_sheet_data)
    self.sheet_data = new_sheet_data
    self.sheet_modified_at = Time.current
  end

  private

  def set_uuid
    self.uuid = Uuidv7Generator.generate
  end
end
