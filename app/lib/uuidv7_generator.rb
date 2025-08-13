class Uuidv7Generator
  class << self
    def generate
      timestamp = (Time.now.to_f * 1000).to_i

      timestamp_bytes = [ timestamp ].pack("Q>")[2..]

      random_bytes = SecureRandom.random_bytes(10)

      version_and_random = random_bytes.unpack("C*")
      version_and_random[0] = (version_and_random[0] & 0x0F) | 0x70
      version_and_random[2] = (version_and_random[2] & 0x3F) | 0x80

      uuid_bytes = timestamp_bytes + version_and_random.pack("C*")

      hex = uuid_bytes.unpack1("H*")
      format_uuid(hex)
    end

    def valid?(uuid)
      return false unless uuid.is_a?(String)
      return false unless uuid.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)

      true
    end

    def extract_timestamp(uuid)
      return nil unless valid?(uuid)

      hex = uuid.delete("-")
      timestamp_hex = hex[0..11]
      timestamp_ms = timestamp_hex.to_i(16)

      Time.at(timestamp_ms / 1000.0)
    end

    def parse(uuid)
      return nil unless valid?(uuid)

      {
        uuid: uuid,
        timestamp: extract_timestamp(uuid),
        version: 7
      }
    end

    private

    def format_uuid(hex)
      "#{hex[0..7]}-#{hex[8..11]}-#{hex[12..15]}-#{hex[16..19]}-#{hex[20..31]}"
    end
  end
end
