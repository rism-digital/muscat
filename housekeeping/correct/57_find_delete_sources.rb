holds = %w(
    2032
37723
66732
73140
73146
73147
85066
85074
123420
123421
123422
138609
161522
161565
161566
161567
161568
161569
161570
161571
161572
184963
210134
210135
240176
240177
240178
240179
240180
262516
272303
272304
273534
281583
284706
284707
286492
297833
313545
313791
317890
318493
318533
318592
318721
318722
319078
319589
319590
320010
329052
329475
330032
330043
330100
330113
51002213
51005835
51005902
51007068
51008626
51009537
51010391
51013408
51016702
51016748
51016823
51016824
51017075
51017084
51017131
)

holds.each do |hid|
    h = Holding.find(hid)
    sid = h.source_id

    versions = PaperTrail::Version.where(item_id: sid)

    version = nil
    if versions.count == 1
        version = versions[0]
    else
        versions.each do |v|
            version = v if v.event == "destroy"
        end
    end

    if version == nil
        puts "#{hid}\t#{sid}"
        next
    end

    date = version.created_at
    who = version.whodunnit
    event = version.event

    src = version.reify

    title = src.title
    composer = src.composer

    puts "#{hid}\t#{sid}\t#{date}\t#{who}\t#{event}\t#{composer}\t#{title}"

end