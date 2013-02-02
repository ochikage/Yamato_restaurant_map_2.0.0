###############################################################################
## **Summary**                                                               ##
## This code is originally created by tab team. Y.Ochi modifed it for Lenovo.##
## Oritinal file could be downloaded from below;                             ##
##                               http://tonchidot.github.com/tab-api-docs/   ##
##                                                                           ##
## **How to install CoffeeScritp**                                           ##
## 1. Download and install Node.js (http://nodejs.jp/)                       ##
## 2. Open cmd.exe                                                           ##
## 3. npm install -g coffee-script                                           ##
##                                                                           ##
## ** How to compile CofeeScript**                                           ##
## 1. Open cmd.exe                                                           ##
## 2. coffee -cj ../main.js main.coffee map.coffee item.coffee parameter.coffee spot.coffee content.coffee ##
##                                                                           ##
## ** References **                                                          ##
## 1. http://d.hatena.ne.jp/nodamushi/20110108/1294518316                    ##
##                                                                           ##
###############################################################################
## @---	12/24/2012	Y.Ochi	Initial version                                  ##
###############################################################################


#Entry point
$(document).ready ->
  content = Content.get()

  resizeContentHeight()
  $(window).bind("resize", resizeContentHeight)
  
  #reload
  $('#reload').bind 'click', ->
    window.location.reload();
    
  #Create select item
  for key, category of CATEGORY
    elm = $("<option>").html(key).attr({value : category})
    $("#item-pickup-category").append(elm)
  
  for key, distance of DISTANCE
    elm = $("<option>").html(key).attr({value : distance})
    $("#item-pickup-distance").append(elm)
  
  #Item Search
  $('#item-pickup-category').bind 'change', ->
    search_item $('#item-pickup-category').val(), $('#item-pickup-input').val(), $('#item-pickup-distance').val()
    false 
  $('#item-pickup-distance').bind 'change', ->
    search_item $('#item-pickup-category').val(), $('#item-pickup-input').val(), $('#item-pickup-distance').val()
    false
  $('#item-pickup-form').bind 'submit', ->
    search_item $('#item-pickup-category').val(), $('#item-pickup-input').val(), $('#item-pickup-distance').val()
    false

  #List control
  $('#clear_button').bind 'click', ->
    content.clearSelect()
    $('.entry').each ->
      $(this).show()

    $('#clear_button').attr('disabled', true)
    $('#item-pickup-category').val("カテゴリ")
    $('#item-pickup-distance').val("距離")
    $('#item-pickup-input').val("")
  
  #Map Search
  $('#mmc-location-button').bind 'click', ->
    content = Content.get()
    content.map.gotoPlace()

  $('#location-search').bind 'submit', ->
    load_address $('#address-input').val()
    false
    
  #Get Center  
  load_mmc_location()

  $('#clear_select').hide()
  
load_mmc_location = ->
  content = Content.get()
  content.load()
  
resizeContentHeight = ->
  contentsHeight = window.innerHeight - $('.navbar').height() - 30
  contentsHeight = 0 if contentsHeight < 0
  $('#map_canvas').height(contentsHeight)
  $('#search-result').height(contentsHeight)

load_address = (address) ->
  geocoder = new google.maps.Geocoder()
  geocoder.geocode { address: address }, (results, status) ->
    content = Content.get()
    if status == google.maps.GeocoderStatus.OK
      content.map.gotoPlace(content.map.gmap.getZoom(), results[0].geometry.location)
    else if address == ""
      content.map.gotoPlace() 
    else
      alert("Geocode failed: #{status}")

api_url = (endpoint) ->
  api_url_base = "http://tab.do/api/1/"
  "#{api_url_base}#{endpoint}.json"

read_user_follow_items = (cb) ->
  url = api_url("users/" + USER_ID + "/items")
  $.get(url, {	}, cb)

search_item = (category, word, distance) ->
  content = Content.get()
  content.getSelect(category, word, distance)
  return true
  