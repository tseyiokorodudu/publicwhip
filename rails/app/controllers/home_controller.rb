class HomeController < ApplicationController
  def index
    @title = "The Public Whip &#8212; ".html_safe
  end
end
