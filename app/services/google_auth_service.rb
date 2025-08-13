class GoogleAuthService
  class << self
    def authorization
      @authorization ||= build_authorization
    end

    def reset_authorization!
      @authorization = nil
    end

    private

    def build_authorization
      GoogleSheetsClient.client.authorization
    end
  end
end
