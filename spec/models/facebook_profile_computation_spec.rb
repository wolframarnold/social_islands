# encoding: utf-8
require 'spec_helper'

describe FacebookProfile do

  context '#collect_friends_location_stats' do

    it 'returns locations map from friends sorted by frequency' do
      exp = [["San Francisco, California, United States", 252], ["Oakland, California, United States", 48],
             ["Berkeley, California, United States", 16], ["New York, New York, United States", 14],
             ["Los Angeles, California, United States", 13], ["San Jose, California, United States", 12],
             ["Fremont, California, United States", 6], ["Chicago, Illinois, United States", 6],
             ["Pleasanton, California, United States", 6], ["Mountain View, California, United States", 4],
             ["Alameda, California, United States", 4], ["Santa Clara, California, United States", 3],
             ["Taipei, Taiwan", 3], ["Paris, France", 3], ["San Mateo, California, United States", 3],
             ["Brussels, Belgium", 3], ["Sacramento, California, United States", 3],
             ["Boulder, Colorado, United States", 3], ["San Rafael, California, United States", 3],
             ["Portland, Oregon, United States", 3], ["Brooklyn, New York, United States", 2],
             ["Eugene, Oregon, United States", 2], ["Emeryville, California, United States", 2],
             ["Dublin, California, United States", 2], ["Berlin, Germany", 2],
             ["Tel Aviv, Israel", 2], ["Palo Alto, California, United States", 2],
             ["Foster City, California, United States", 2], ["Boston, Massachusetts, United States", 2],
             ["Concord, California, United States", 2], ["Menlo Park, California, United States", 2],
             ["Washington, District of Columbia, United States", 1], ["Salzburg, Austria", 1], ["Daejeon, Korea", 1],
             ["Las Vegas, Nevada, United States", 1], ["Ho Chi Minh City, Vietnam", 1], ["Marburg, Germany", 1],
             ["Neustrelitz", 1], ["Brisbane, California, United States", 1], ["Moscow, Russia", 1],
             ["Redwood Shores, California, United States", 1], ["Ljubljana, Slovenia", 1],
             ["Coogee, New South Wales, Australia", 1], ["San Antonio, Texas, United States", 1],
             ["Castro Valley, California, United States", 1], ["Austin, Texas, United States", 1],
             ["Bellevue, Washington, United States", 1], ["Springfield, Oregon, United States", 1],
             ["Jersey City, New Jersey, United States", 1], ["Santa Barbara, California, United States", 1],
             ["Culver City, California, United States", 1], ["San Carlos, California, United States", 1],
             ["Sendai-shi, Miyagi, Japan", 1], ["Pleasant Hill, California, United States", 1],
             ["Salt Lake City, Utah, United States", 1], ["Suwon", 1], ["Fort Worth, Texas, United States", 1],
             ["Geneva, Switzerland", 1], ["Ann Arbor, Michigan, United States", 1],
             ["Walnut Creek, California, United States", 1], ["Philadelphia, Pennsylvania, United States", 1],
             ["Sunnyvale, California, United States", 1], ["Saarbrücken", 1], ["Lima, Peru", 1],
             ["Phoenix, Arizona, United States", 1], ["Willemstad, Netherlands Antilles", 1], ["Mesagne", 1],
             ["Long Beach, California, United States", 1], ["Cerritos, California, United States", 1],
             ["Mexico City, Mexico", 1], ["Nevada City, California, United States", 1], ["Ga`Aton, Hazafon, Israel", 1],
             ["Stamford, Connecticut, United States", 1], ["Groningen", 1], ["Athens, Greece", 1], ["Beijing, China", 1],
             ["Salem, Massachusetts, United States", 1], ["Uppsala, Sweden", 1], ["Munich, Germany", 1],
             ["Kingston, Jamaica", 1], ["Corte Madera, California, United States", 1],
             ["Richmond, California, United States", 1], ["Astoria, New York, United States", 1],
             ["Guadalajara, Jalisco", 1], ["Kensington, California, United States", 1], ["Twin cities, United States", 1],
             ["Zaragoza, Spain", 1], ["Nashville, Tennessee, United States", 1], ["Yopal, Casanare", 1],
             ["Lancaster, Pennsylvania, United States", 1], ["London, United Kingdom", 1],
             ["South San Francisco, California, United States", 1], ["Livermore, California, United States", 1],
             ["Milan, Italy", 1], ["Hayward, California, United States", 1], ["Pahoa, Hawaii, United States", 1],
             ["Pisticci, Basilicata, Italy", 1], ["Healdsburg, California, United States", 1],
             ["Charlottesville, Virginia, United States", 1], ["Raleigh, North Carolina, United States", 1],
             ["San Miguel de Allende, Guanajuato", 1], ["El Sobrante, California, United States", 1],
             ["Stockholm, Sweden", 1], ["La Jolla, California, United States", 1], ["São Paulo, Brazil", 1],
             ["Salvador, Bahia, Brazil", 1], ["Hong Kong", 1], ["Atherton, California, United States", 1],
             ["Neuville-sur-Saône", 1]]

      wei_fp = FactoryGirl.create(:wei_fb_profile)

      wei_fp.collect_friends_location_stats.should == exp
    end

  end
end