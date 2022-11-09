
def up
    ActiveRecord::Base.connection.execute("DELETE FROM digital_objects WHERE attachment_file_name IS NULL")


    DigitalObject.all.each do |instance|
        file = instance.attachment_file_name.gsub("'", "\\'") rescue file = ""
        ActiveRecord::Base.connection.execute(
            "INSERT INTO active_storage_blobs ( id, active_storage_blobs.key, filename, content_type, metadata, byte_size, checksum, created_at) VALUES (
            '#{instance.id}',
            '#{SecureRandom.uuid}',
            '#{file}',
            '#{instance.attachment_content_type}',
            '{}',
            '#{instance.attachment_file_size}',
            '0',
            '#{instance.attachment_updated_at.to_datetime rescue Time.now.to_datetime}'
            )"
        )
    end


    ## Do some cleanup
    ActiveRecord::Base.connection.execute("DELETE FROM digital_object_links WHERE ID IN (2879, 17296, 18999, 19591, 20004, 20787, 21912)")

    DigitalObjectLink.find_each.each do |instance|
        ActiveRecord::Base.connection.execute(
        "INSERT INTO active_storage_attachments (name, record_type, record_id, blob_id, created_at) VALUES (
        'image',
        '#{instance.object_link_type}',
        '#{instance.object_link_id}',
        '#{instance.digital_object_id}',
        '#{instance.updated_at.to_datetime}'
        )"
    )
    end

  end

  def key(instance, attachment)
    SecureRandom.uuid
    # Alternatively:
    # instance.send("#{attachment}_file_name")
  end

  def checksum(attachment)
    # local files stored on disk:
    url = attachment.path
    Digest::MD5.base64digest(File.read(url))

    # remote files stored on another person's computer:
    # url = attachment.url
    # Digest::MD5.base64digest(Net::HTTP.get(URI(url)))
  end

up