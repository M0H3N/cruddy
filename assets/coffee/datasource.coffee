class DataSource extends Backbone.Model
    defaults:
        data: []
        search: ""

    initialize: (attributes, options) ->
        @entity = entity = options.entity
        @filter = filter = new Backbone.Model

        @options =
            url: entity.url()
            dataType: "json"
            type: "get"
            displayLoading: yes

            success: (resp) =>
                @_hold = true
                @set resp
                @_hold = false

                @trigger "data", this, resp.data

            error: (xhr) => @trigger "error", this, xhr

        @listenTo filter, "change", =>
            @set current_page: 1, silent: yes
            @fetch()

        @on "change", => @fetch() unless @_hold
        @on "change:search", => @set current_page: 1, silent: yes unless @_hold

    hasData: -> not _.isEmpty @get "data"

    hasMore: -> @get("current_page") < @get("last_page")

    isFull: -> not @hasMore()

    inProgress: -> @request?

    holdFetch: ->
        @_hold = yes

        return this

    fetch: ->
        @_hold = no

        @request.abort() if @request?

        @options.data = @data()

        @request = $.ajax @options

        @request.always => @request = null

        @trigger "request", this, @request

        @request

    more: ->
        return if @isFull()

        @set current_page: @get("current_page") + 1, silent: yes

        @fetch()

    data: ->
        data =
            order_by: @get "order_by"
            order_dir: @get "order_dir"
            page: @get "current_page"
            per_page: @get "per_page"
            keywords: @get "search"

        filters = @filterData()

        data.filters = filters unless _.isEmpty filters
        data.columns = @columns.join "," if @columns?

        data

    filterData: ->
        data = {}

        for key, value of @filter.attributes when not _.isEmpty value
            data[key] = value

        return data
