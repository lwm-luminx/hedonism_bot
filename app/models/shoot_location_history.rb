# frozen_string_literal: true

# A bounded match within an explicitly recorded session. Never extrapolate a phone's
# position outside the session or across gaps in GPS reception.
class ShootLocationHistory
  MAX_GAP = 120

  def self.valid?(recordings)
    recordings.is_a?(Array) && recordings.size <= 100 && recordings.all? do |recording|
      next false unless recording.is_a?(Hash)

      start = Time.iso8601(recording.fetch("startedAt"))
      stop = Time.iso8601(recording.fetch("stoppedAt"))
      samples = recording.fetch("samples")
      stop >= start && samples.is_a?(Array) && samples.size <= 50_000 && samples.all? do |sample|
        timestamp = Time.iso8601(sample.fetch("timestamp"))
        timestamp.between?(start, stop) &&
          sample.fetch("latitude").is_a?(Numeric) && sample["latitude"].between?(-90, 90) &&
          sample.fetch("longitude").is_a?(Numeric) && sample["longitude"].between?(-180, 180) &&
          sample.fetch("accuracy").is_a?(Numeric) && sample["accuracy"].between?(0, 100)
      end
    end
  rescue KeyError, ArgumentError, TypeError, NoMethodError
    false
  end

  def self.sample_at(recordings, time)
    return unless time

    recordings.flat_map do |recording|
      next [] unless time.between?(Time.iso8601(recording.fetch("startedAt")), Time.iso8601(recording.fetch("stoppedAt")))

      recording.fetch("samples")
    end.select { |sample| (Time.iso8601(sample.fetch("timestamp")) - time).abs <= MAX_GAP }
      .min_by { |sample| (Time.iso8601(sample.fetch("timestamp")) - time).abs }
  end

  def self.venue_at(recordings, time)
    sample = sample_at(recordings, time)
    return unless sample

    point = RGeo::Geographic.simple_mercator_factory.point(sample.fetch("longitude"), sample.fetch("latitude"))
    # Require a venue envelope; the nearest venue anywhere in the world is not evidence.
    candidates = Venue.joins(:location).where("ST_Covers(locations.envelope::geometry, ?)", point)
    candidates.limit(2).to_a.then { |venues| venues.first if venues.size == 1 }
  end
end
