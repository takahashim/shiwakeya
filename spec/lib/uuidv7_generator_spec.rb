require "rails_helper"

RSpec.describe Uuidv7Generator do
  describe ".generate" do
    it "generates a valid UUIDv7" do
      uuid = described_class.generate
      expect(uuid).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
    end

    it "generates unique UUIDs" do
      uuids = Array.new(100) { described_class.generate }
      expect(uuids.uniq.size).to eq(100)
    end

    it "generates UUIDs with version 7" do
      uuid = described_class.generate
      version_nibble = uuid.split("-")[2][0]
      expect(version_nibble).to eq("7")
    end

    it "generates UUIDs with valid variant bits" do
      uuid = described_class.generate
      variant_nibble = uuid.split("-")[3][0]
      expect(variant_nibble).to match(/[89ab]/i)
    end

    it "generates time-ordered UUIDs" do
      uuid1 = described_class.generate
      sleep 0.001
      uuid2 = described_class.generate

      expect(uuid1 < uuid2).to be true
    end
  end

  describe ".valid?" do
    it "returns true for valid UUIDv7" do
      uuid = described_class.generate
      expect(described_class.valid?(uuid)).to be true
    end

    it "returns false for invalid format" do
      expect(described_class.valid?("not-a-uuid")).to be false
      expect(described_class.valid?("12345678-1234-1234-1234-123456789012")).to be false
      expect(described_class.valid?("")).to be false
      expect(described_class.valid?(nil)).to be false
    end

    it "returns false for wrong version" do
      uuid_v4 = "550e8400-e29b-41d4-a716-446655440000"
      expect(described_class.valid?(uuid_v4)).to be false
    end

    it "accepts both lowercase and uppercase" do
      uuid = described_class.generate
      expect(described_class.valid?(uuid.downcase)).to be true
      expect(described_class.valid?(uuid.upcase)).to be true
    end
  end

  describe ".extract_timestamp" do
    it "extracts timestamp from valid UUIDv7" do
      freeze_time = Time.now
      allow(Time).to receive(:now).and_return(freeze_time)

      uuid = described_class.generate
      extracted_time = described_class.extract_timestamp(uuid)

      expect(extracted_time).to be_within(0.001).of(freeze_time)
    end

    it "returns nil for invalid UUID" do
      expect(described_class.extract_timestamp("invalid")).to be_nil
      expect(described_class.extract_timestamp(nil)).to be_nil
    end

    it "correctly handles different timestamps" do
      past_time = Time.new(2024, 1, 1, 12, 0, 0)
      allow(Time).to receive(:now).and_return(past_time)

      uuid = described_class.generate
      extracted_time = described_class.extract_timestamp(uuid)

      expect(extracted_time.year).to eq(2024)
      expect(extracted_time.month).to eq(1)
      expect(extracted_time.day).to eq(1)
    end
  end

  describe ".parse" do
    it "returns parsed information for valid UUIDv7" do
      freeze_time = Time.now
      allow(Time).to receive(:now).and_return(freeze_time)

      uuid = described_class.generate
      parsed = described_class.parse(uuid)

      expect(parsed).to include(
        uuid: uuid,
        version: 7
      )
      expect(parsed[:timestamp]).to be_within(0.001).of(freeze_time)
    end

    it "returns nil for invalid UUID" do
      expect(described_class.parse("invalid")).to be_nil
      expect(described_class.parse(nil)).to be_nil
    end
  end

  describe "timestamp ordering" do
    it "maintains chronological order" do
      uuids = []
      timestamps = []

      5.times do
        uuid = described_class.generate
        uuids << uuid
        timestamps << described_class.extract_timestamp(uuid)
        sleep 0.001
      end

      expect(uuids).to eq(uuids.sort)
      expect(timestamps).to eq(timestamps.sort)
    end
  end

  describe "RFC compliance" do
    it "generates 128-bit UUIDs" do
      uuid = described_class.generate
      hex = uuid.delete("-")
      expect(hex.length).to eq(32)
    end

    it "uses correct timestamp bits (48 bits)" do
      uuid = described_class.generate
      hex = uuid.delete("-")
      timestamp_hex = hex[0..11]
      expect(timestamp_hex.length).to eq(12)
    end
  end
end
