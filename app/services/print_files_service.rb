class PrintFilesService
  attr_reader :print_file_data

  BASE_IMAGE     = 'printfiles/blank_12000_ed7sn2.pdf'
  H_TO_W_RATIO   = 3/2.0
  BASE_WIDTH     = 2
  BASE_MULTIPLE  = 4000
  WIDTH          = BASE_WIDTH * BASE_MULTIPLE 
  HEIGHT         = BASE_WIDTH * H_TO_W_RATIO * BASE_MULTIPLE 
  SHEET_ITEM_MAP = { 
    'CUS' => {item_name: 'cards', image_width: 0.375, qty_per_sheet: 8},
    'CUS - BAM' => {item_name: 'cards', image_width: 0.375, qty_per_sheet: 8}, 
    'CUS-PVC-WHT-LFT' => {item_name: 'cards', image_width: 0.375, qty_per_sheet: 8}, 
    'CUS-Tap-WHT' => {item_name: 'taps', image_width: 0.300, qty_per_sheet: 16} 
  }

  def initialize(params)
    @params          = params
    @print_file_data = []
  end

  def generate
    filtered_rows = filter_rows
    build_print_files(filtered_rows)
  end

  def build_print_files(filtered_rows)
    raw_print_file_urls = []

    until filtered_rows.empty?
      # Get the SKU of incoming items, and determine how many to print per sheet
      item_sku       = filtered_rows[0][:item_sku]
      item_map       = SHEET_ITEM_MAP[item_sku]
      these_n_images = filtered_rows.shift(item_map[:qty_per_sheet])
      order_ids      = these_n_images.map {|row| row[:order_id] }.uniq.sort.join(', ')
      final_filename = these_n_images.map {|row| "#{row[:order_id]}-(#{these_n_images.select{|r| r[:order_id] == row[:order_id] }.count})"}.uniq.sort.join('_')

      transformations = these_n_images.each_with_index.collect do |image_data, index|
        base_64_image_url = Base64.encode64(image_data[:image_url]).gsub("\n", '')
        position_map = send("#{item_map[:item_name]}_position_map".to_sym)

        {
          overlay: "fetch:#{base_64_image_url}",
          width: (item_map[:image_width] * BASE_MULTIPLE).to_i,
          x: (position_map[(index + 1).to_s][:x] * BASE_MULTIPLE).to_i,
          y: (position_map[(index + 1).to_s][:y] * BASE_MULTIPLE).to_i,
          gravity: 'north_west'
        }
      end

      raw_url = Cloudinary::Utils.cloudinary_url(BASE_IMAGE, transformation: transformations)

      raw_print_file_urls << { 
        filename: final_filename, 
        url: raw_url,
        order_ids: order_ids,
        item_sku: item_sku 
      }
    end

    threads = []
    raw_print_file_urls.each do |data|
      threads << Thread.new do
        image = Cloudinary::Uploader.upload(data[:url], folder: "printfiles", public_id: data[:filename], attachment: true, timeout: 180)
        
        webhook_data = {
          image_url: image['url'],
          order_ids: data[:order_ids],
          item_sku: data[:item_sku]
        }

        headers  = { "Content-Type": "application/json" }
        response = Faraday.post('https://hooks.zapier.com/hooks/catch/5011016/opvnyex/', webhook_data.to_json, headers)
        puts "Order ids: #{data[:order_ids]} == #{response.status}"
      end
    end

    threads.each { |aThread| aThread.join }
  end

  def filter_rows
    rows = []
    @params[:array].each do |spreadsheet_row|
      quantity = spreadsheet_row[4]

      filtered_row = {
        quantity: quantity,
        order_id: spreadsheet_row[5],
        item_sku: spreadsheet_row[7],
        image_url: spreadsheet_row[8]
      }

      quantity.times { rows << filtered_row }
    end

    rows
  end

  def cards_position_map
    {
      '1' => {x: 0.24, y: 0.22},
      '2' => {x: 1.21, y: 0.22},
      '3' => {x: 0.24, y: 0.885},
      '4' => {x: 1.21, y: 0.885},
      '5' => {x: 0.24, y: 1.55},
      '6' => {x: 1.21, y: 1.55},
      '7' => {x: 0.24, y: 2.215},
      '8' => {x: 1.21, y: 2.215},
    }
  end

  def taps_position_map
    
  end

end
