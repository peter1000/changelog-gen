child = require 'child_process'
util = require 'util'

GIT_LOG_CMD = 'git log %s -E --format=%s %s | cat'
GIT_LAST_TAG_CMD = 'git describe --tags --abbrev=0'
GIT_TAGS_CMD = 'git tag'
GIT_FIRST_COMMIT = 'git rev-list HEAD | tail -n 1'

get_all_tags = ->
  deferred = q.defer()
  child.exec GIT_TAGS_CMD, (code, stdout, stderr) ->
    if code
      deferred.resolve []
    else
      deferred.resolve stdout.split('\n').filter (s) -> s.length isnt 0

  deferred.promise

get_previous_tag = ->
  deferred = q.defer()
  child.exec GIT_LAST_TAG_CMD, (code, stdout, stderr) ->
    if code
      get_first_commit().then (commit) ->
        deferred.resolve commit
    else
      deferred.resolve stdout.replace('\n', '')

  deferred.promise

get_first_commit = ->
  deferred = q.defer()
  child.exec GIT_FIRST_COMMIT, (code, stdout, stderr) ->
    if code
      deferred.reject "Cannot get the first commit."
    else
      deferred.resolve stdout.replace('\n', '')

  deferred.promise

read_git_log = (grep, from, to='HEAD') ->
  deferred = q.defer()

  grep = if grep?
    "--grep=\"#{grep}\""
  else
    ''

  range = if from?
    "#{from}..#{to}"
  else
    ''

  cmd = util.format(GIT_LOG_CMD, grep, '%H%n%s%n%b%n==END==', range)

  child.exec cmd, (code, stdout, stderr) ->
    commits = []
    stdout.split('\n==END==\n').forEach (rawCommit) ->
      commit = rawCommit.split('\n').filter((s) -> s.length).join('\n')
      commits.push commit if commit

    deferred.resolve commits

  deferred.promise