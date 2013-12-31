$ ->

  $('.headline-fragment').tooltip()

  $(document).on "click", ".save-headline-button", ->
    $(@).closest('form').submit()

  window.userSignedIn = -> $("body").hasClass('logged-in')

  generate_new = ->

    $("#invent-button").addClass 'disabled'
    $("#invent-button").removeClass 'enabled'

    $("#generate-form .alert").addClass('hidden')

    # Get checked sources
    source_names = $("#generate-form input:checkbox:checked").map(->
      $(this).attr('name')
    ).get()
    window.generator_last_source_names = source_names
    window.generator_last_depth = 2 #$("#generate-form input:radio[name=depth]:checked").val();

    # Build query string
    query = $.param({depth:window.generator_last_depth, sources:source_names.join(",")})

    # Build URL
    url = $("#generate-form").data('generator-url') + "?" + query

    $.getJSON url, (data) ->
      $("#generated-headlines").html HandlebarsTemplates[if window.userSignedIn() then 'generator/results' else 'generator/results_signed_out'](data)
    .fail ->
      $("#generate-form .alert").removeClass('hidden')
    .always ->
      $('.headline-fragment').tooltip()
      $("#invent-button").removeClass 'disabled'
      $("#invent-button").addClass 'enabled'

  # Auto-generate when opening generator page
  if $("#invent-button").length > 0
    generate_new()

  $("#invent-button").on 'click', ->
    generate_new()


Handlebars.registerHelper 'authenticity_token', ->
  $('meta[name="csrf-token"]').attr('content')

Handlebars.registerHelper 'sources_json', ->
  JSON.stringify @sources

Handlebars.registerHelper 'save_url', ->
  $("#generate-form").data('save-url')
