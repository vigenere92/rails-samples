class SearchService

  def self.cleanUrl url
    begin
      uri = Domainatrix.parse( url.strip )
      uri.domain
    rescue
      puts "Errored out for #{url}"
    end
  end

  def self.tagsQuery tags
    query = []
      query.append( {
        "terms" => {
          "resourceTags" => tags
        }
      } )
      query.append( {
        "terms" => {
          "suggestedTags" => tags
        }
      } )

    query
  end

  def self.subscriberQuery streamIds
    query = []
    streamIds.each do |id|
      query.append( {
        "term" => {
          "streamId.keyword" => id
        }
      } )
    end

    query
  end

  def self.followingQuery followingIds
    [
      {
      "terms" => {
        "submitterUserIds.keyword" => followingIds
      }
    }
  ]
  end

  def self.urlsQuery urls
    query = []
    urls.each do |url|
      query.append( {
        "match" => {
          "url" => ".*#{url}.*"
        }
      } )
    end

    query
  end

  # Format results from elasticsearch
  def self.format_results(results, page, size)
    hits = results[ "hits" ]
    totalResults = hits[ "total" ].to_i
    if !hits.nil? && !hits["hits"].nil?
      hits = hits["hits"]
      results = hits.map { |hit| hit["_source"] }
      if page*size < totalResults
        hasMore = true
      else
        hasMore = false
      end

      { results: results, hasMore: hasMore, currentPage: page }
    else
      []
    end
  end

  def self.getSort filter
    if filter == 'popular'
      sort = [
        {
          "ratingsCount" => {
            "order" => "desc"
          }
        },
        {
          "opinionsCount" => {
            "order" => "desc"
          }
        },
        {
          "createdAt" => {
            "order" => "desc"
          }
        }
      ]
    else
      sort = [
        {
          "createdAt" => {
            "order" => "desc"
          }
        },
        {
          "ratingsCount" => {
            "order" => "desc"
          }
        },
        {
          "opinionsCount" => {
            "order" => "desc"
          }
        }
      ]
    end

    sort
  end

  def self.getFilterQuery( stream )
    {
      "bool" => {
        "filter" => {
          "term" => {
            "streamId.keyword" => stream
          }
        }
      }
    }
  end

  # All collections
  def self.allCollections( page=1 )
    size = 15
    from = (page-1)*size

    query = {
      "from" => from,
      "size" => size,
      "sort" =>  [
        {
          "upvoteCount" => {
            "order" => "desc"
          }
        }
      ]
    }

    results = conn.search( index: 'processed', type: 'collections', body: query )
    format_results(results, page, size)
  end

  # All resources
  def self.allResources( page=1, filter=nil, stream=nil )
    size = 10
    from = (page-1)*size

    query = {
      "from" => from,
      "size" => size,
      "sort" => getSort( filter )
    }

    if !stream.nil?
      query[ "query" ] = getFilterQuery( stream )
    end

    results = conn.search( index: 'processed', type: 'resources', body: query )
    format_results(results, page, size)
  end

  # Fetch recommendations for the logged in user from elaticsearch. These recommendations are based on the
  # tags added by user, people the user follows and the urls user has submitted( in this order of priority)
  #
  # It is passed a user object and the page of recommendations requested
  def self.userRecommendations( user, page=1, filter=nil )
    size = 20
    from = (page-1)*size

    followingUserIds = user.following

    #userTags = user.tags.group( :name ).order( 'count_all desc' ).count.take(300).reduce( [] ) { |acc, ele| acc.append( ele[ 0 ] ); acc }
    resourceIds = user.ratings.pluck(:resource_id).compact
    #suggestedTags = Resource.where( id: resourceIds ).pluck(:suggested_tags).reduce( [] ) { |acc, tags| acc = acc + tags; acc }.take(200)

    #userUrls = user.user_urls.pluck( :url ).map { |url| cleanUrl( url ) }.uniq
    subscribedStreams = user.streams.pluck(:id)

    shouldQuery = followingQuery( followingUserIds ) + subscriberQuery( subscribedStreams )

    query = {
      "from" => from,
      "size" => size,
      "query" => {
        "bool" => {
          "minimum_should_match" => 1,
          "should" => shouldQuery,
          "must_not" => [
            {
              "terms" => {
                "id.keyword" => resourceIds
              }
            },
            {
              "term" => {
                "submitterUserIds.keyword" => user.id
              }
            }
          ]
        }
      },
      "sort" => getSort( filter )
    }

    results = conn.search( index: 'processed', type: 'resources', body: query )
    format_results(results, size, page)
  end

  def self.resourceRecommendations( resource, page=1, userId=nil )
    size = 10
    from = (page-1)*size
    resourceTags = resource.tags.pluck(:name).uniq
    resourceUserId = resource.user_id
    shouldQuery = tagsQuery( resourceTags )
    shouldQuery += followingQuery( [ resourceUserId ] ) if resourceUserId != userId

    query = {
      "from" => from,
      "size" => size,
      "query" => {
        "bool" => {
          "minimum_should_match" => 1,
          "should" => shouldQuery,
          "must_not" => [
            {
              "match" => {
                "id" => resource.id
              }
            }
          ]
        }
      }
    }
    if !userId.nil?
      query[ "query" ][ "bool" ][ "must_not" ].append( {
        "match" => {
          "submitterUserIds" => userId
        }
      } )
    end

    results = conn.search( index: 'processed', type: 'resources', body: query )
    format_results(results, size, page)
  end

  def self.conn
    @conn = @conn || Elasticsearch::Client.new( host: "*********")
  end
end
