require 'puppet/face'
require 'puppet/util/puppetdb'
require 'puppet/util/terminal'
require 'puppet/util/colors'
require 'puppet/network/http_pool'
require 'uri'
require 'time'
require 'json'

Puppet::Face.define(:report, '0.0.1') do
  extend Puppet::Util::Colors
  action :unresponsive do
    summary "Queries puppetdb for report" 
    arguments "<none>"

    option "--deactive" do
      summary "Show both active and deactive nodes"
      default_to { false }
    end

    option "--minutes MINUTES" do
      summary "The number of minutes to check the delta against"
      default_to { 60 }
    end


    description <<-'EOT'
      This is a simple wrapper to connect to puppetdb for exported records
    EOT
    notes <<-'NOTES'
      Directly connects to the puppetdb server using your local certificate
    NOTES
    examples <<-'EOT'
      # Show all reports with failed status

      $ puppet report export  --status failed
    EOT

    when_invoked do |options|
      connection = Puppet::Network::HttpPool.http_instance(Puppet::Util::Puppetdb.server,Puppet::Util::Puppetdb.port)

      query = ["and",["=",["node","active"],true]]
      json_query = URI.escape(query.to_json)

      unless reports = PSON.load(connection.request_get("/v4/nodes/?query=#{json_query}", {"Accept" => 'application/json'}).body)
        raise "Error parsing json output of puppet search #{reports}"
      end
      Puppet.debug(reports)
      reports
    end

    when_rendering :console do |events,options|
      if events.empty?
        Puppet.notice("No reports found")
      end
      output = []
      events.each do |event|
        Puppet.debug(event['report-timestamp'])
        delta = (Time.now - DateTime.parse(event['report-timestamp']).to_time)
        human =  '%d days,%d hours,%d minutes,%d seconds' %
        # the .reverse lets us put the larger units first for readability
        [24,60,60].reverse.inject([delta]) {|result, unitsize|
          result[0,0] = result.shift.divmod(unitsize)
          result
        } 
        if delta / 60 >= options[:minutes].to_i
          output << [event['certname'],event['report-environment'],event['report-timestamp'],human].join(',')
        end
      end
      output
    end
  end
end
