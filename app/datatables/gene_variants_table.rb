class GeneVariantsTable
  delegate :params, to: :@view_context

  def initialize(view_context)
    @view_context = view_context
  end

  def as_json(options = {})
    {
      result: data,
      total: total_events.size
    }
  end

  private
  def data
    events.map { |e| GeneVariantRowPresenter.new(e) }
  end

  def events
    @events ||= filter_events(order_events(page_events(get_events)))
  end

  def total_events
    @total_events = filter_events(get_events)
  end

  def get_events
    Event.index_scope
  end

  def page_events(events)
    events.page(page).per(count)
  end

  def filter_events(events)
    if filter_params = params['filter']
      filter_params.inject(events) do |e, (col, term)|
        col = column_map(col)
        if col == 'genes.entrez_id'
          e.where("CAST(#{col} as VARCHAR) ILIKE :search", search: "%#{term}%")
        else
          e.where("#{col} ILIKE :search", search: "%#{term}%")
        end
      end
    else
      events
    end
  end

  def order_events(events)
    if sort_params = params['sorting']
      sort_params.inject(events) do |e, (col, direction)|
        e.order("#{column_map(col)} #{sort_direction(direction)}")
      end
    else
      events
    end
  end

  def page
    params[:page].to_i
  end

  def count
    params[:count].to_i
  end

  def column_map(col)
    @@columns[col]
  end

  def sort_direction(dir)
    dir == 'desc' ? 'desc' : 'asc'
  end

  @@columns = {
    'entrez_gene'      => 'genes.name',
    'entrez_id'        => 'genes.entrez_id',
    'variant'          => 'events.name',
    'gene_category'    => 'categories.name',
    'protein_function' => 'protein_functions.name',
  }
end