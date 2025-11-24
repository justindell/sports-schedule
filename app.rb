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
    data = HTTParty.get(@url)
    return [] unless data

    data["events"].filter_map do |event|
      time = Time.parse(event["date"])
      next unless time > Time.now

      Event.new(event["name"], time.getlocal, event.dig("links", 0, "href"))
    end
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
