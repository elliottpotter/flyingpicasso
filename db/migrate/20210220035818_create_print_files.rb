class CreatePrintFiles < ActiveRecord::Migration[6.0]
  def change
    create_table :print_files do |t|

      t.timestamps
    end
  end
end
