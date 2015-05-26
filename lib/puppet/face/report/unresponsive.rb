require 'puppet/face'
begin
require 'puppet/util/puppetdb'
rescue
  Puppet.warning("Unable to automatically lookup puppetdb server information")
end
require 'puppet/network/http_pool'
require 'uri'
require 'time'
require 'json'

Puppet::Face.define(:report, '0.0.1') do
  action :unresponsive do
    summary "Queries puppetdb for unresponsive nodes based on local clock"
    arguments "<none>"

    option "--minutes MINUTES" do
      summary "The number of minutes to check the delta against"
      default_to { 60 }
    end

    option "--host HOSTNAME" do
      summary "The hostname of the puppetdb server"
      default_to { Puppet::Util::Puppetdb.server }
    end

    option "--port PORT" do
      summary "The port of the puppetdb server"
      default_to { Puppet::Util::Puppetdb.port }
    end


    description <<-'EOT'
      This is a simple wrapper to connect to puppetdb and display unresponsive nodes
    EOT
    notes <<-'NOTES'
      Directly connects to the puppetdb server using your local agent certificate
      Note: You must have whitelisted this certificate, masters work out of the box
    NOTES
    examples <<-'EOT'
      # Show all nodes that have not checked in the last 60 minutes 

      $ puppet report unresponsive
      # Show all nodes that have not checked in the last 120 minutes 

      $ puppet report unresponsive --minutes 120
      certname,environment,report-timestamp,days,hours,minutes,seconds
    EOT

    when_invoked do |options|
      connection = Puppet::Network::HttpPool.http_instance(options[:host],options[:port])

      query = ["and",["=",["node","active"],true]]
      json_query = URI.escape(query.to_json)

      unless nodes = PSON.load(connection.request_get("/v4/nodes/?query=#{json_query}", {"Accept" => 'application/json'}).body)
        raise "Error parsing json output of puppet search #{nodes}"
      end
      Puppet.debug(nodes)
      nodes 
    end

    when_rendering :console do |reports,options|
      Puppet.debug(options)
      if reports.empty?
        Puppet.notice("No reports older then #{(options[:minutes] || 60)} minutes found")
      end
      output = Hash.new 
      reports.each do |report|
        # Calculate delta between last run and now in seconds
        delta = (Time.now - DateTime.parse(report['report-timestamp']).to_time)

        # Calculate a human readable timestamp
        human_timestamp =  '%d days,%d hours,%d minutes,%d seconds' %
        [24,60,60].reverse.inject([delta]) {|result, unitsize|
          result[0,0] = result.shift.divmod(unitsize)
          result
        }
        # Only return values that match our predicate
        if (delta / 60) >= (options[:minutes] || 60).to_i
          output[delta] = [ report['certname'],
                            report['report-environment'],
                            report['report-timestamp'],
                            human_timestamp
                          ].join(',')
        end
      end
      output.sort_by{|key, value| key}.reverse.map{|key,value| value}
    end
  end
end
