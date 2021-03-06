@filteredUsers = new Mongo.Collection 'filtered-users'
@channelAutocomplete = new Mongo.Collection 'channel-autocomplete'

Template.messagePopupConfig.helpers
	popupUserConfig: ->
		self = this
		template = Template.instance()
		config =
			title: t('People')
			collection: filteredUsers
			template: 'messagePopupUser'
			getInput: self.getInput
			textFilterDelay: 200
			getFilter: (collection, filter) ->
				exp = new RegExp("#{filter}", 'i')
				template.userFilter.set filter
				if template.userSubscription.ready()
					items = filteredUsers.find({$or: [{username: exp}, {name: exp}]}, {limit: 5}).fetch()

					all =
						_id: '@all'
						username: 'all'
						system: true
						name: t 'Notify_all_in_this_room'
						compatibility: 'channel group'

					exp = new RegExp("(^|\\s)#{filter}", 'i')
					if exp.test(all.username) or exp.test(all.compatibility)
						items.unshift all
					return items
				else
					return []

			getValue: (_id, collection, firstPartValue) ->
				if _id is '@all'
					if firstPartValue.indexOf(' ') > -1
						return 'all'

					return 'all:'

				username = collection.findOne(_id)?.username

				if firstPartValue.indexOf(' ') > -1
					return username

				return username + ':'

		return config

	popupChannelConfig: ->
		self = this
		template = Template.instance()
		config =
			title: t('Channels')
			collection: channelAutocomplete
			trigger: '#'
			template: 'messagePopupChannel'
			getInput: self.getInput
			textFilterDelay: 200
			getFilter: (collection, filter) ->
				exp = new RegExp(filter, 'i')
				template.channelFilter.set filter
				if template.channelSubscription.ready()
					return collection.find( { name: exp }, { limit: 5 }).fetch()
				else
					return []

			getValue: (_id, collection) ->
				return collection.findOne(_id)?.name

		return config

	popupSlashCommandsConfig: ->
		self = this
		template = Template.instance()

		config =
			title: t('Commands')
			collection: RocketChat.slashCommands.commands
			trigger: '/'
			triggerAnywhere: false
			template: 'messagePopupSlashCommand'
			getInput: self.getInput
			getFilter: (collection, filter) ->
				commands = []
				for command, item of collection
					if command.indexOf(filter) > -1
						commands.push
							_id: command
							params: item.params
							description: item.description

					if commands.length > 10
						break

				commands = commands.sort (a, b) ->
					return a._id > b._id

				return commands

		return config

	emojiEnabled: ->
		return RocketChat.emoji?

	popupEmojiConfig: ->
		if RocketChat.emoji?
			self = this
			template = Template.instance()
			config =
				title: t('Emoji')
				collection: RocketChat.emoji.list
				template: 'messagePopupEmoji'
				trigger: ':'
				prefix: ''
				getInput: self.getInput
				getFilter: (collection, filter) ->
					results = []
					for shortname, data of collection
						if shortname.indexOf(filter) > -1
							results.push
								_id: shortname
								data: data

						if results.length > 10
							break

					if filter.length >= 3
						results.sort (a, b) ->
							a.length > b.length

					return results

		return config

	subscriptionNotReady: ->
		return 'notready' unless Template.instance().subscriptionsReady()

Template.messagePopupConfig.onCreated ->
	@userFilter = new ReactiveVar ''
	@channelFilter = new ReactiveVar ''

	template = @
	@autorun ->
		template.userSubscription = template.subscribe 'filteredUsers', template.userFilter.get()

	@autorun ->
		template.channelSubscription = template.subscribe 'channelAutocomplete', template.channelFilter.get()

