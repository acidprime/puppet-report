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
  action :export do
    summary "Queries puppetdb for report" 
    arguments "<none>"

    option "--highlight" do
      summary "Enable colorized output"
      default_to { false }
    end

    option "--status REPORT_STATUS" do
      summary "Filter reports by status {failed,unchanged,changed,noop}"
      default_to { 'failed' }
    end

    description <<-'EOT'
      This is a simple wrapper to connect to puppetdb for exported records
    EOT
    notes <<-'NOTES'
      Directly connects to the puppetdb server using your local certificate
    NOTES
    examples <<-'EOT'
      List all exported resources:

      $ puppet report export 
    EOT

    when_invoked do |options|
      connection = Puppet::Network::HttpPool.http_instance(Puppet::Util::Puppetdb.server,Puppet::Util::Puppetdb.port)


      query = ["and",["=",["node","active"],true],["=","status",options[:status]]] 

      json_query = URI.escape(query.to_json)
      unless reports = PSON.load(connection.request_get("/v4/reports/?query=#{json_query}", {"Accept" => 'application/json'}).body)
        raise "Error parsing json output of puppet search #{filtered}"
      end
      reports
    end

    when_rendering :console do |reports,options|
      if reports.empty?
        Puppet.notice("No reports found")
      end
      output = []
      reports.each do |report|
        output << [
                  report['certname'],
                  report['environment'],
                  report['configuration-version'],
                  DateTime.parse(report['end-time']).rfc2822,
                  report['end-time'],
                  report['hash'],
                  ].join(',')
      end
      output
    end
  end
end
