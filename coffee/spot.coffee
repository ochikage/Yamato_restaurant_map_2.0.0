###############################################################################
## @---	01/16/2013	Y.Ochi	Initial version                                  ##
###############################################################################
class Spot
  constructor: (name, latlng)->
    @name = name
    @count = 1
    @latlng = latlng
    
    @marker = null
    @balloon = null
    @balloonFn = null
    @IsBalloonOpened = true
    
  renderContext: ->
    {
      spot_name: @name
      spot_count: @count
    }
    
  infoHtml: ->
    template = Handlebars.compile($('#info-window-template').html())
    template(@renderContext())
    
  createInfoHtml: ()->
    @balloon = new google.maps.InfoWindow({content: @infoHtml()})
  
