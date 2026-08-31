require "sinatra"
require "httparty"
require "json"
require "net/http"
require "uri"
require "time"

set :bind, "0.0.0.0"
set :port, 8000

class Schedule
  SCHEDULES = [
    "https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/teams/16/schedule",
    "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/3/schedule",
    "https://site.api.espn.com/apis/site/v2/sports/football/college-football/teams/356/schedule",
    "https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/teams/356/schedule"
  ].freeze

  # ESPN/Akamai blocks HTTParty's default "Ruby" User-Agent with a 403 HTML page.
  REQUEST_HEADERS = {
    "User-Agent" => "SportsSchedule/1.0",
    "Accept" => "application/json"
  }.freeze

  Event = Data.define(:event, :date, :link) do
    def to_h
      {
        event: event,
        date:  date.strftime("%a %b %d %I:%M %p"),
        link:  link
      }
    end
  end

  def self.all
    SCHEDULES
      .map { |schedule| new(schedule) }
      .flat_map(&:fetch_team_events)
      .sort_by(&:date)
      .first(5)
      .map(&:to_h)
  end

  def initialize(url)
    @url = url
  end

  def fetch_team_events
    response = HTTParty.get(@url, headers: REQUEST_HEADERS)
    return [] unless response.success?

    events = response["events"]
    return [] unless events.is_a?(Array)

    events.filter_map do |event|
      time = Time.parse(event["date"])
      next unless time > Time.now

      Event.new(full_name(event), time.getlocal, event.dig("links", 0, "href"))
    end
  end

  private

  def full_name(event)
    "#{event['name']} (#{event.dig('competitions', 0, 'broadcasts', 0, 'media', 'shortName')})"
  end
end

get "/games" do
  content_type :json
  { data: Schedule.all }.to_json
end

get "/" do
  content_type :json
  { ok: true, endpoints: ["/games"] }.to_json
end
