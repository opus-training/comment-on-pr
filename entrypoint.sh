#!/usr/bin/env ruby

require "json"
require "octokit"

json = File.read(ENV.fetch("GITHUB_EVENT_PATH"))
event = JSON.parse(json)


github = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])

message = ARGV[0]
delete_prev_regex_msg = ARGV[2]

repo = event["repository"]["full_name"]

if ENV.fetch("GITHUB_EVENT_NAME") == "pull_request"
  pr_number = event["number"]
else
  pulls = github.pull_requests(repo, state: "open")

  push_head = event["after"]
  pr = pulls.find { |pr| pr["head"]["sha"] == push_head }

  if !pr
    puts "Couldn't find an open pull request for branch with head at #{push_head}."
    exit(1)
  end
  pr_number = pr["number"]
end

coms = github.issue_comments(repo, pr_number)

coms.each do |n|
  if n["body"].match(/#{delete_prev_regex_msg}/)
    github.delete_comment(repo, n["id"], opt = {})
  end
end

github.add_comment(repo, pr_number, message)
