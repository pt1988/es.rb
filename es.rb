#!/usr/bin/ruby
require 'multi_json'
require 'json'
require 'faraday'
require 'elasticsearch/api'

#client = Elasticsearch::Client.new log: true

class MySimpleClient
  include Elasticsearch::API

  CONNECTION = ::Faraday::Connection.new url: 'http://localhost:9200'

  def perform_request(method, path, params, body)
#    puts "--> #{method.upcase} #{path} #{params} #{body}"

    CONNECTION.run_request \
      method.downcase.to_sym,
      path,
      ( body ? MultiJson.dump(body): nil ),
      {'Content-Type' => 'application/json'}
  end
end

class Agent
   def initialize()
	@client = MySimpleClient.new
    end
    def get_indices()
	_indices_array = []
	_indices_list_raw = @client.indices.get_aliases
	_indices_list = JSON.parse(_indices_list_raw)
	_indices_list.each do |key, value|
#puts "#{a.length}"
#	puts "#{key}"
		_indices_array.push(key)
	end
	return _indices_array
    end

    def refresh_index(index_name)
	return @client.indices.refresh index: index_name
    end

    def flush_index(index_name)
	return @client.indices.flush index: index_name
    end

    def delete_index(index_name)
	@client.indices.flush index: index_name
	#puts "delete index #{index_name}"
	return @client.indices.delete index: index_name
	#result=@client.delete_by_query index: index_name , body: { query: {match_all: {}} }
	#@client.indices.flush index: index_name
	return result
    end
end
client = MySimpleClient.new
 client.cluster.health
# --> GET _cluster/health {}
# => "{"cluster_name":"elasticsearch" ... }"

#p client.index index: 'myindex', type: 'mytype', id: 'custom', body: { title: "Indexing from my client" }
#p JSON.parse(agent.delete_index("logstash-2015.10.02"))
fuction=ARGV[0]

if (fuction == "list")
	agent = Agent.new
	puts agent.get_indices
elsif(fuction == "flush")
	agent = Agent.new
	for i in 1..ARGV.count-1
		result=JSON.parse(agent.flush_index(ARGV[i]))
		puts "\"{#{ARGV[i]}\":#{result}}"
	end
elsif(fuction == "refresh")
	agent = Agent.new
	for i in 1..ARGV.count-1
		result=JSON.parse(agent.refresh_index(ARGV[i]))
		puts "{\"#{ARGV[i]}\":#{result}}"
	end
elsif(fuction == "delete")
	agent = Agent.new
	for i in 1..ARGV.count-1
		result=JSON.parse(agent.delete_index(ARGV[i]))
		puts "{\"#{ARGV[i]}\":#{result}}"
	end
else
	puts "[command]                      | description "
	puts "list                           | for show indices list "
	puts "refresh [index_1] .. [index_N] | for refresh index"
	puts "flush [index_1] .. [index_N]   | for fulsh index"
	puts "delete [index_1] .. [index_N]  | for remove index"
end

#p client.indices.delete index: 'test'
