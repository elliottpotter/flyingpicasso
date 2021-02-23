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
          quality: 100,
          gravity: 'north_west'
        }
      end

      raw_url = Cloudinary::Utils.cloudinary_url(BASE_IMAGE, transformation: transformations)
      image   = Cloudinary::Uploader.upload(raw_url, folder: "printfiles", public_id: final_filename, attachment: true)
      
      data = {
        image_url: image['url'],
        order_ids: order_ids,
        item_sku: item_sku
      }

      headers  = { "Content-Type": "application/json" }
      response = Faraday.post('https://hooks.zapier.com/hooks/catch/5011016/opvnyex/', data.to_json, headers)
      puts "Order ids: #{order_ids} == #{response.body}"
    end
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
      '1' => {x: 0.185, y: 0.215},
      '2' => {x: 1.155, y: 0.215},
      '3' => {x: 0.185, y: 0.865},
      '4' => {x: 1.155, y: 0.865},
      '5' => {x: 0.185, y: 1.515},
      '6' => {x: 1.155, y: 1.515},
      '7' => {x: 0.185, y: 2.165},
      '8' => {x: 1.155, y: 2.165},
    }
  end

  def taps_position_map
    
  end

end

def getsvgs(order_id)
  url = URI("https://api.zakeke.com/api/graphql")
  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true
  request = Net::HTTP::Post.new(url)
  request["authorization"] = "Bearer 2sT0EU1f4ifdrSgpN-sF0Y5Z_jeursA6f8IgYpV-0S2Z2Zc_pufXk3ycMnxjtQI74xWdGcSPhcVM9OV-a1dTFHTfBG79n-2NP7DYigQ670Jf9B8G0sKbWqyz2NhrHbXfpFoizW2_6ItY1z_vdE5iQbcOzRdOP0Vc5lo-UYnXadD023AoxC-4PWtqhrOANFHnE_WDWiisPA5FeO5GO_o3UmsYUXhgIwInbLj6ffo4zN5TylxcIFC1bpNZmHAA3miehu2vdWqCMRJ6O5osIUfckdCmbC1CdjQ1UM2gboCX3T1vrJQVqsxFm-0Ls1ebsMoxLGT_G2-lhwhCJ_VgIpZZNcBqH_WaiUWu_LdO8XEeWmcE-51oid6eA2WMC_ecJvUmmOhJfRLtPmTHOYsmJBF00o1y6_K2u3Mbmw77uTTz6E6WpWP_WTse9bYpAK71_buHy7sM3zzVJ4e2SiRfwH9wKzI16X_grbAWD0y790b94EwXqPrIPp7iWtufR9lNGoK-hk6sGU4AkRN548v_uI4dbK6JsadKuhagiqloZ8z-dDMqd7lJ"
  request["Content-Type"] = "application/json"
  request.body = "{\n    \"name\":\"orderQuery\",\n    \"query\":\"query orderQuery(\\n  $id: ID!\\n) {\\n  order(id: $id) {\\n    orderCode\\n    ecommerceOrderNumber\\n    orderDate\\n    isPaid\\n    showPayButton\\n    details {\\n      ...orderDetail_detail\\n      id\\n    }\\n    id\\n  }\\n}\\n\\nfragment DesignMainOutputFiles_urls on Design {\\n  mainOutputFilesUrls {\\n    key\\n    value\\n  }\\n}\\n\\nfragment DesignPreviews_previews on Design {\\n  previews\\n}\\n\\nfragment orderDetail_detail on OrderDetail {\\n  id\\n  designID\\n  modelID\\n  modelName\\n  quantity\\n  zipFileUrl\\n  design {\\n    ...DesignPreviews_previews\\n    ...DesignMainOutputFiles_urls\\n  }\\n}\\n\",\n    \"variables\": {\n        \"id\": \"guid://Zakeke/Order/#{order_id}\"\n        }\n    }"
  response = https.request(request)
  body = JSON.parse(response.read_body)
  urls = body.dig('data', 'order', 'details', 0, 'design', 'mainOutputFilesUrls')
  if urls.count > 0
    svg = urls.find{ |urls| urls['key'] == 'SVG' }['value']
    shopify_order_id = body.dig('data', 'order', 'ecommerceOrderNumber')
    @results << { order_id: shopify_order_id, svg: svg } if svg.present? && shopify_order_id.present?
    puts @results[@results.count - 1] if @results.count % 10 == 0
  end
  sleep 0.5
end
