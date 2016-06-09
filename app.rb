require "json"
require "sequel"
require "sinatra"

DB = Sequel.connect(ENV["PAGINATION_DB"])

module Helpers
  DEFAULT_PAGE_LIMIT = 200
  DEFAULT_ORDER = :asc

  def process_options(id, options)
    max = DEFAULT_PAGE_LIMIT
    dir = DEFAULT_ORDER
    return [max, id, :asc] if options.nil?

    options.split(',').each do |o|
      max = $1.to_i if o =~ /max=(.*)/
      dir = $1.strip.downcase.to_sym if o =~ /order=(.*)/
    end

    # need to convert order into sequel column and direction
    order = if dir == :asc
      id
    else
      Sequel.desc(id)
    end
    [max, order, dir]
  end

  def cast_type(id, value)
    # simple casting, if :id then int, otherwise leave as string
    (id == :id) ? value.to_i : value
  end

  def process_range(id, range)
    range.gsub!('[', '') # remove optional '[' inclusive operator
    exclusive = range[0] == ']' # is the leading range value exclusive?
    lo, hi = range.gsub(']', '').split('..')
    return nil if lo.nil? && hi.nil?

    if lo.nil?
      ["? <= ?", id, cast_type(id, hi)]
    else
      if hi.nil?
        ["? #{exclusive ? '>' : '>='} ?", id, cast_type(id, lo)]
      else
        ["(? #{exclusive ? '>' : '>='} ?) AND (? <= ?)", id, cast_type(id, lo), id, cast_type(id, hi)]
      end
    end
  end

  def page_limits(range)
    return {id: :id, where: nil, max: DEFAULT_PAGE_LIMIT, order: :id, dir: :asc} if range.nil?

    # yes I can probably create some crazy regex to do this in one line with captures
    # however, I'm trying to write stable code quickly here, so readable is a good goal :)
    values, options = range.split(';')
    id, id_range = values.split(' ')
    id = id.to_sym
    max, order, dir = process_options(id, options)
    where = process_range(id, id_range)

    {
      id: id,
      where: where,
      max: max,
      order: order,
      dir: dir
    }
  end
end

helpers Helpers

get "/" do
  limits = page_limits(request.env["HTTP_RANGE"])
  logger.info limits.inspect

  apps = if limits[:where].nil?
    DB[:apps].limit(limits[:max]).order(limits[:order]).all
  else
    DB[:apps].where(*limits[:where]).limit(limits[:max]).order(limits[:order]).all
  end

  if apps.size > 0
    # only add the headers if there was a returned result set,
    # i.e. at the last page if there is no Next-Range
    data = limits[:id]
    first_id = apps.first[data]
    last_id = apps.last[data]

    # don't forget to fixup range for desc
    if limits[:dir] == :asc
      headers["Content-Range"] = "#{data} #{first_id}..#{last_id}"
      headers["Next-Range"] = "#{data} ]#{last_id}..; max=#{limits[:max]}"
    else
      headers["Content-Range"] = "#{data} #{last_id}..#{first_id}"
      headers["Next-Range"] = "#{data} ]#{last_id}..; max=#{limits[:max]}, order=desc"
    end
  end
  JSON.generate(apps)
end
