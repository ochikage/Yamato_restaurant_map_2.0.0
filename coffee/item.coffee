###############################################################################
## @---	12/24/2012	Y.Ochi	Initial version                                  ##
###############################################################################

class Item
  constructor: (@data) ->
    #Reclip count
    #@data.title += "(" + @data.reclip_count + ")";
    #calc distance
    to_lat = 0;
    to_lon = 0;
    if @data.places[0].lat? then to_lat = @data.places[0].lat
    if @data.places[0].lon? then to_lon = @data.places[0].lon
    to = new google.maps.LatLng(to_lat, to_lon)
    from = new google.maps.LatLng(INIT_LATITUDE, INIT_LONGTITUDE)
    @distance = google.maps.geometry.spherical.computeDistanceBetween(from, to)

  renderContext: ->
    updated_at = new Date(@data.updated_at)
    now = new Date()
    passedDate = (now - updated_at) / (1000 * 60 * 60 * 24)

    #sometimes those values are returned as null
    item_img_s = ""
    item_img_m = ""
    if @data.image_urls[0]? then item_img_s = @data.image_urls[0].crop_S
    if @data.image_urls[0]? then item_img_m = @data.image_urls[0].crop_M
    
    spot_id = 0
    spot_name = ""
    if @data.places[0]? then spot_id = @data.places[0].id
    if @data.places[0]? then spot_name = @data.places[0].name


    {
      id: @data.id
      short_title: truncate(@data.title, 20)
      title: @data.title
      short_description: truncate(@data.description, 50)
      long_description: truncate(@data.description, 300)
      image_url_small: item_img_s
      image_url: item_img_m
      profile_image_url: @data.user.profile_image_url.crop_S
      tab_url: "https://tab.do/items/#{@data.id}"
      stream_url: "https://tab.do/streams/#{@data.stream.id}"
      stream_title: @data.stream.title
      is_new: passedDate < 1
      spot_id: spot_id
      spot_name: spot_name
      distance: Math.round(@distance)
    }

  html: ->
    template = Handlebars.compile($('#entry-template').html())
    template(@renderContext())

  latlng: ->
    if @data.places.length > 0
      place = @data.places[0]
      new google.maps.LatLng(place.lat, place.lon)
  
  getItemId: ->
    return @data.id
    
  getSpotId: ->
    id = 0;
    if @data.places[0]?
      id = @data.places[0].id
    return id;
  
  getSpotName: ->
    name = "N/A";
    if @data.places[0]?
      name = @data.places[0].name
    return name;
    
  getTitle: ->
    return @data.title
    
  getDescription: ->
    return @data.description
    
  getListElement: ->
    return @list_el
    
  setListElement: (list_el)->
    @list_el = list_el
    
  truncate = (string, maxchars) ->
    if !string? then ""

    if string.length <= maxchars || maxchars <= 3
      string
    else
      string[0...(maxchars - 3)] + '...'
