# Adds google analytics event tracking
# TODO: only run this is google analytics is loaded
$ ->
  # subscribe to policy
  $('.subscribe-button-form-subscribe .btn').on 'click',  (e) ->
    ga('send', 'event', 'policy', 'subscribe')

  # unsubscribe to policy
  $('.subscribe-button-form-unsubscribe .btn').on 'click',  (e) ->
    ga('send', 'event', 'policy', 'unsubscribe')
