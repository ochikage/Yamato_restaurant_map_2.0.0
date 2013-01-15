###############################################################################
## @---	12/24/2012	Y.Ochi	Initial version                                  ##
###############################################################################
 
class Map
  _instance = undefined
  
  #Call map with get whenever you need the instance
  @get: (latlng = new google.maps.LatLng(INIT_LATITUDE,INIT_LONGTITUDE)) ->
    if _instance?
      _instance.setCenter(latlng)
    else
      _instance = new Map(latlng)
    _instance

  constructor: (latlng, zoom=SEARCH_ZOOM_LEVEL) ->
    #initialize
    @markers = []
    @openGroupedInfoWindowFn = {}
    @zorder = 0 
    @loaded_data = null
    @grouped_marker_array = []
    
    #Prepare map
    myOptions = {
      zoom: zoom
      center: latlng
      mapTypeId: google.maps.MapTypeId.ROADMAP
      scrollwheel: false
    }
    
    @gmap = new google.maps.Map(document.getElementById('map_canvas'), myOptions)

    template = Handlebars.compile($('#refresh-control-template').html())
    control = $(template({}))[0]
    google.maps.event.addDomListener(control, 'click', =>
      @load()
    )
    @gmap.controls[google.maps.ControlPosition.TOP_RIGHT].push(control)


  setCenter: (latlng) ->
    @gmap.setCenter(latlng)


  createGroupedMarkers: (new_item) ->
    latlng = new_item.latlng()
    id = new_item.item.places[0].id
    if latlng?
      if !@grouped_marker_array[id]?
        @grouped_marker_array[id] = new GroupedMarker
        
      @grouped_marker_array[id].count++
      @grouped_marker_array[id].name = new_item.item.places[0].name
      @grouped_marker_array[id].latlng = latlng

  #Marker
  showGroupedMarkers: ->
    for key, grouped_marker of @grouped_marker_array
      marker = new google.maps.Marker(
        {
          position: grouped_marker.latlng
          map: @gmap
        }
      )
      grouped_marker.createInfoHtml()
      grouped_marker.marker = marker
      @bindBalloonToMarker key

  bindBalloonToMarker: (index) -> 
    grouped_marker = @grouped_marker_array[index]
    @openGroupedInfoWindowFn[index] = =>
      if grouped_marker.openedInfoWindows  # when balloon pops
        # Hide other markers
        for marker in @markers
          if marker.getPosition() != grouped_marker.latlng
            marker.setVisible(false)
        # Hide other lists
        $('.entry').each ->
          id = $(this).data("spot-id")
          if id != parseInt(index)
            $(this).hide()

        grouped_marker.infoWindow.open(@gmap, grouped_marker.marker)    
        grouped_marker.openedInfoWindows = false
      
        $('#clear_select').show(500)
        $('#clear_select').bind 'click', (event) =>
          @clearSelect()
        
      else  # when balloon hides
        # Show other markers
        for marker in @markers
          marker.setVisible(true)
        # Show other lists
        $('.entry').each ->
          $(this).show()
        grouped_marker.infoWindow.close()
        grouped_marker.openedInfoWindows = true 
        $('#clear_select').hide()
        
    google.maps.event.addListener grouped_marker.marker, 'click', @openGroupedInfoWindowFn[index]
    @markers.push(grouped_marker.marker)
  
  clearSelect: ->
    #hide balloons
    for key, grouped_marker of @grouped_marker_array
      grouped_marker.infoWindow.close?()
      grouped_marker.openedInfoWindows = true
    
    #show markers
    for marker in @markers
      marker.setVisible(true)
    
    # Show lists
    $('.entry').each ->
      $(this).show()

    $('#clear_select').hide()
      
  clearMarkers: ->
    for item in @loaded_data.items
      if item.infoWindow?
        item.infoWindow.close()
        item.infoWindow = null

    for marker in @markers
      marker.setMap(null)
      
    @markers = []
    @openGroupedInfoWindowFn = {}

  load: (latlng = @gmap.getCenter()) -> 
    console.log("load")
	
    result_div = $('#search-result')
    result_div.empty()
    result_div.html("<div class='loading-text'>Loading...</div>")

    read_nearby_popular_with_current_map_range = =>
      bounds = @gmap.getBounds()
      if bounds?
        console.log bounds.toString()
        dist = google.maps.geometry.spherical.computeDistanceBetween(bounds.getNorthEast(), bounds.getSouthWest())
        
        read_user_follow_items (data) =>
          console.log("data loaded")
          console.log(data)  
          @loaded_data = data;
          @update();
      else
        setTimeout(read_nearby_popular_with_current_map_range, 1000)
    read_nearby_popular_with_current_map_range()


  update: (target = ".*", category = ".*", word = ".*") ->
    console.log("update")
    result_div = $('#search-result')
    result_div.empty()

    @clearMarkers()
    @grouped_marker_array = []
    @zorder = 0
	
    if !@loaded_data? then return

    for item in @loaded_data.items
      item_instance = new Item item

      #Search
      bTitle = item.title.match(new RegExp(target)) && item.title.match(new RegExp(category)) && item.title.match(new RegExp(word))
      bDescription = item.description.match(new RegExp(target)) && item.description.match(new RegExp(category)) && item.description.match(new RegExp(word)) 
      if !(bTitle || bDescription) then continue 
			
      result_div.append(item_instance.html())
      @createGroupedMarkers(item_instance)
      @showGroupedMarkers() 
      
    $('.item_title').bind 'click', (event) =>
      spot_id = $(event.currentTarget).parents("li.entry").data('spot-id')
      @openGroupedInfoWindowFn[spot_id]()

class GroupedMarker
  constructor: ->
    @name = ""
    @count = 0
    @latlng = null
    @infoWindow = null
    @openedInfoWindows = true
    @marker = null
    
  renderContext: ->
    {
      spot_name: @name
      spot_count: @count
    }
    
  infoHtml: ->
    template = Handlebars.compile($('#info-window-template').html())
    template(@renderContext())
    
  createInfoHtml: ()->
    @infoWindow = new google.maps.InfoWindow({content: @infoHtml()})

