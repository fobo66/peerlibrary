crypto = Npm.require 'crypto'

Accounts.onCreateUser (options, user) ->
  try
    person =
      user:
        id: user._id
        username: user.username
      slug: user.username

    _.extend person, _.pick(options.profile or {}, 'foreNames', 'lastName', 'work', 'education', 'publications')

    personId = Persons.insert person
    user.person =
      id: personId
    user.gravatarHash = crypto.createHash('md5').update(user.emails?[0]?.address).digest('hex')
  catch e
    if e.name isnt 'MongoError'
      throw e
    # TODO: Improve when https://jira.mongodb.org/browse/SERVER-3069
    if /E11000 duplicate key error index:.*Persons\.\$slug/.test e.err
      throw new Meteor.Error 403, 'Username conflicts with existing slug.'
    throw e
  user

Meteor.publish 'users-by-username', (username) ->
  Meteor.users.find
      username: username
    ,
      fields:
        username: 1
        person: 1

Meteor.publish 'user-data', ->
  Meteor.users.find
    _id: @userId
  ,
    fields:
      gravatarHash: 1
