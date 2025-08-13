class DriveService
  def get_last_modified_time(file_id)
    require "google/apis/drive_v3"

    service = Google::Apis::DriveV3::DriveService.new
    service.authorization = GoogleAuthService.authorization

    file = service.get_file(
      file_id,
      fields: "modifiedTime"
    )

    Time.parse(file.modified_time)
  end
end
