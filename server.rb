
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
        topic = topic_string(@categories, id)
        title = $redis.hget("#{topic}", "title")
        # title = $redis.hget("#{@categories}:#{id}", "title")
        title = "#{title}*):(*#{id}"
      end
      # binding.pry
      render(:erb, :topics, { :layout => :default_layout })
    end

    post('/categories/:topics') do
      @categories = params[:topics]
      @title = params["title"]
      @comment = params["topic"]
      like = params["like"]
      dislike = params["dislike"]

      # binding.pry
      id=$redis.incr("#{@categories}:id")
      topic = topic_string(@categories, id)
      $redis.hmset("#{topic}", "title", @title, "topic", @comment)
      # $redis.hmset("#{@categories}:#{id}", "title", @title, "topic", @comment)
      $redis.lpush("#{@categories}:ids", id)

      $redis.set("#{topic}:like", like)
      # $redis.set("#{@categories}:#{id}:like", like)
      $redis.set("#{topic}:dislike", dislike)
      # $redis.set("#{@categories}:#{id}:dislike", dislike)
      redirect("/categories/#{@categories}")
    end

    get('/categories/:topics/new') do
      @categories = params[:topics]
      render(:erb, :new_topic, { :layout => :default_layout })
    end

    get('/categories/:topics/comments') do
      @categories = params[:topics]
      @id = params["id"]
      tlike = params["tlike"]
      tdislike = params["tdislike"]
      clike = params["clike"]
      cdislike = params["cdislike"]
      index = params["index"].to_i
      # binding.pry
      topic = topic_string(@categories, @id)

      if tlike == "true"
        $redis.incr("#{topic}:like")
        # $redis.incr("#{@categories}:#{@id}:like")
      end

      if tdislike == "true"
        $redis.incr("#{topic}:dislike")
        # $redis.incr("#{@categories}:#{@id}:dislike")
      end

      comment = comment_string(@categories, @id)
      if clike == "true"
        cindex = $redis.lindex("#{comment}:ids", index)
        # cindex = $redis.lindex("#{@categories}:topic:#{@id}:comment:ids", index)

        comment_like = comment_l_and_d(@categories, @id, cindex)
        like = $redis.hget(comment_like, "like").to_i
        # like = $redis.hget("#{@categories}:topic:#{@id}:comment:#{cindex}", "like").to_i
        like+=1
        # binding.pry
        $redis.hset(comment_like, "like", like)
        # $redis.hset("#{@categories}:topic:#{@id}:comment:#{cindex}", "like", like)
      end

      if cdislike == "true"
        cindex = $redis.lindex("#{comment}:ids", index)
        # cindex = $redis.lindex("#{@categories}:topic:#{@id}:comment:ids", index)


        dislike = dislikes_for_comment(@categories,@id,cindex)
        dislike+=1
        # binding.pry
        comment_dislike = comment_l_and_d(@categories, @id, cindex)
        $redis.hset(comment_dislike, "dislike", dislike)
        # $redis.hset("#{@categories}:topic:#{@id}:comment:#{cindex}", "dislike", dislike)
      end

      # binding.pry
      @tlike = $redis.get("#{topic}:like")
      # @tlike = $redis.get("#{@categories}:#{@id}:like")
      @dislike = $redis.get("#{topic}:dislike")
      # @dislike = $redis.get("#{@categories}:#{@id}:dislike")
      @topic = $redis.hgetall(topic)
      # @topic = $redis.hgetall("#{@categories}:#{@id}")
      @num_comments = $redis.lrange("#{comment}:ids", 0, -1)
      # @num_comments = $redis.lrange("#{@categories}:topic:#{@id}:comment:ids", 0, -1)
      @comments = @num_comments.map do |num|
        $redis.hgetall("#{comment}:#{num}")
        # $redis.hgetall("#{@categories}:topic:#{@id}:comment:#{num}")
      end
      # @comments = $redis.lrange("#{@categories}:comments:#{@id}", 0, -1)
      # binding.pry
      render(:erb, :comments, { :layout => :default_layout })
    end

    post('/categories/:topics/comments') do
      @categories = params[:topics]
      @id = params["id"]
      @comment = params["comment"]
      like = params["like"]
      dislike = params["dislike"]

      comment = comment_string(@categories, @id)
      id=$redis.incr("#{comment}:id")
      # id=$redis.incr("#{@categories}:topic:#{@id}:comment:id")
      set_comment = comment_l_and_d(@categories, @id, id)
      $redis.hmset(set_comment, "comment", @comment, "like", like, "dislike", dislike)
      # $redis.hmset("#{@categories}:topic:#{@id}:comment:#{id}", "comment", @comment, "like", like, "dislike", dislike)
      $redis.lpush("#{comment}:ids", id)
      # $redis.lpush("#{@categories}:topic:#{@id}:comment:ids", id)
      # binding.pry
      redirect("/categories/#{@categories}/comments?id=#{@id}")
    end

    def topic_string(categories, id)
      "#{categories}:#{id}"
    end

    def comment_string(categories, id)
      "#{categories}:topic:#{id}:comment"
    end

    def comment_l_and_d(categories, id, index)
      comment = comment_string(categories, id)
      "#{comment}:#{index}"
    end

    def dislikes_for_comment(category,topic_id,comment_index)
      comment = comment_l_and_d(category,topic_id,comment_index)
      $redis.hget("#{comment}", "dislike").to_i
    end

  end
end
