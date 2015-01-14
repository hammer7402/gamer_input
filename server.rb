
module GamerInput
  class Server < Sinatra::Base

    enable :logging

    configure :development do
      require 'pry'
      register Sinatra::Reloader
      $redis = Redis.new # defaults to 127.0.0.1:6379
    end

    get('/') do
      redirect('/categories')
    end

    get('/categories') do
      render(:erb, :index, { :layout => :default_layout })
    end

    get('/categories/:topics') do
      @categories = params[:topics]
      # binding.pry
      ids = $redis.lrange("#{@categories}:ids", 0, -1)
      @titles = ids.map do |id|
        title = $redis.hget("#{@categories}:#{id}", "title")
        title = "#{title}*):(*#{id}"
      end
      # binding.pry
      render(:erb, :topics, { :layout => :default_layout })
    end

    post('/categories/:topics') do
      @categories = params[:topics]
      @title = params["title"]
      @comment = params["topic"]
      # binding.pry
      id=$redis.incr("#{@categories}:id")
      $redis.hmset("#{@categories}:#{id}", "title", @title, "topic", @comment)
      $redis.lpush("#{@categories}:ids", id)
      redirect("/categories/#{@categories}")
    end

    get('/categories/:topics/new') do
      @categories = params[:topics]
      render(:erb, :new_topic, { :layout => :default_layout })
    end

    get('/categories/:topics/comments') do
      @categories = params[:topics]
      @id = params["id"]
      @topic = $redis.hgetall("#{@categories}:#{@id}")
      # binding.pry
      render(:erb, :comments, { :layout => :default_layout })
    end

    post('/categories/:topics/comments') do
      @categories = params[:topics]
      binding.pry
    end

  end
end
