require 'puppet/face'
begin
require 'puppet/util/puppetdb'
rescue
  Puppet.warning("Unable to automatically lookup puppetdb server information")
end
require 'puppet/network/http_pool'
require 'puppet/util/terminal'
require 'puppet/util/colors'
require 'uri'
require 'time'
require 'json'


Puppet::Face.define(:report, '0.0.1') do
  extend Puppet::Util::Colors
  action :display do
    summary "Queries puppetdb and display events from a report"
    arguments "<report_hash>"

    option "--host HOSTNAME" do
      summary "The hostname of the puppetdb server"
      default_to { Puppet::Util::Puppetdb.server }
    end

    option "--port PORT" do
      summary "The port of the puppetdb server"
      default_to { Puppet::Util::Puppetdb.port }
    end

    option "--highlight" do
      summary "Enable colorized output"
      default_to { true }
    end

    description <<-'EOT'
      This is a simple wrapper to connect to puppetdb for listing reports
    EOT
    notes <<-'NOTES'
      Directly connects to the puppetdb server using your local certificate
    NOTES
    examples <<-'EOT'
      # Show all reports with failed status

      $ puppet report export  --status failed
      # Show all reports with changed status
      
      $ puppet report export  --status changed
    EOT

    when_invoked do |report_hash,options|
      connection = Puppet::Network::HttpPool.http_instance(options[:host],options[:port])

      query = ["and",["=", "report",report_hash]]

      query << ["=",["node","active"],true] unless options[:deactive]

      json_query = URI.escape(query.to_json)
      unless events = PSON.load(connection.request_get("/v4/events/?query=#{json_query}", {"Accept" => 'application/json'}).body)
        raise "Error parsing json output of puppet search: #{events}"
      end
      Puppet.debug(events)
      output = [ {'Resource' => 'Message'} ]
      output << events.map { |event| Hash["#{event['resource-type'].capitalize}[#{event['resource-title']}]" => event['message']]}
      output.flatten
    end

    when_rendering :console do |events,report_hash,options|
      if events.empty?
        Puppet.notice("No events found in report, failed to compile?")
      end
      padding = '  '
      headers = {
        'resource'   => 'Name',
        'message'     => 'message',
      }

      min_widths = Hash[ *headers.map { |k,v| [k, v.length] }.flatten ]
      min_widths['resource'] = min_widths['message'] = 40

      min_width = min_widths.inject(0) { |sum,pair| sum += pair.last } + (padding.length * (headers.length - 1))

      terminal_width = [Puppet::Util::Terminal.width, min_width].max

      highlight = proc do |color,s|
        c = colorize(color, s)
        c
      end
      n = 0
      events.collect do |results|

        columns = results.inject(min_widths) do |resource,message|
          {
            'resource'   => resource.length,
            'message' => message.length,
          }
        end

        flex_width = terminal_width - columns['resource'] - columns['message'] - (padding.length * (headers.length - 1))

        format = %w{resource message}.map do |k|
          "%-#{ [ columns[k], min_widths[k] ].max }s"
        end.join(padding)
        results.map do |resource,message|
          n += 1
          Puppet.debug("#{options.inspect}")
          if n.odd?
            (options[:highlight] && highlight[ :hwhite,format % [ resource, message ] ] || format % [ resource, message ])
          else
            (options[:highlight] && highlight[ :white,format % [ resource, message ] ] || format % [ resource, message ])
          end
        end.join
      end
    end
  end
end
