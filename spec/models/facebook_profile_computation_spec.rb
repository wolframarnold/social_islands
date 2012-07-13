# encoding: utf-8
require 'spec_helper'

describe FacebookProfile do

  context '.uid2joined_on' do

    it "it reports 2004-1-1 for UID's < 100_000" do
      FacebookProfile.uid2joined_on(1_000).should == Date.civil(2004,1,1)
      FacebookProfile.uid2joined_on(10_000).should == Date.civil(2004,1,1)
      FacebookProfile.uid2joined_on(99_999).should == Date.civil(2004,1,1)
    end

    it "it reports 2007-1-1 for UID's < 100_000_000" do
      FacebookProfile.uid2joined_on(   100_000).should == Date.civil(2007,1,1)
      FacebookProfile.uid2joined_on( 1_000_000).should == Date.civil(2007,1,1)
      FacebookProfile.uid2joined_on(10_000_000).should == Date.civil(2007,1,1)
      FacebookProfile.uid2joined_on(99_999_999).should == Date.civil(2007,1,1)
    end

    it "it reports 2009-6-1 for UID's < 100_000_000" do
      FacebookProfile.uid2joined_on(    100_000_000).should == Date.civil(2009,6,1)
      FacebookProfile.uid2joined_on(  1_000_000_000).should == Date.civil(2009,6,1)
      FacebookProfile.uid2joined_on( 10_000_000_000).should == Date.civil(2009,6,1)
      FacebookProfile.uid2joined_on(100_000_000_000).should == Date.civil(2009,6,1)
      FacebookProfile.uid2joined_on(999_999_999_999).should == Date.civil(2009,6,1)
    end

    context "UID's > 100_000_000_000" do
      date_samples = [ [100_000_241_077_339, Date.civil(2009, 9,24)],
                       [100_000_498_112_056, Date.civil(2009,11,22)],
                       [100_000_525_348_604, Date.civil(2009,12,10)],
                       [100_000_585_319_862, Date.civil(2009,12,27)],
                       [100_000_772_928_057, Date.civil(2010, 2,18)],
                       [100_000_790_642_929, Date.civil(2010, 2,28)],
                       [100_001_590_505_220, Date.civil(2010,10, 2)],
                       [100_003_240_296_778, Date.civil(2011,12,21)],
                       [100_003_811_911_948, Date.civil(2012, 5, 8)],
                       [100_003_875_801_329, Date.civil(2012, 5,16)] ]

      date_samples.each do |uid, date|
        it "maps #{uid} to #{date}" do
          FacebookProfile.uid2joined_on(uid).should == date
        end
      end

      interpolation_samples = [ [  1_000_000_000_000, Date.civil(2009, 6, 1)],
                                [ 10_000_000_000_000, Date.civil(2009, 6, 1)],
                                [100_000_000_000_000, Date.civil(2009, 7,31)],
                                [100_000_250_000_000, Date.civil(2009, 9,26)],
                                [100_000_500_000_000, Date.civil(2009,11,23)],
                                [100_000_750_000_000, Date.civil(2010, 2,11)],
                                [100_001_000_000_000, Date.civil(2010, 4,25)],
                                [100_001_250_000_000, Date.civil(2010, 7, 2)],
                                [100_001_500_000_000, Date.civil(2010, 9, 7)],
                                [100_001_750_000_000, Date.civil(2010,11,14)],
                                [100_002_000_000_000, Date.civil(2011, 1,20)],
                                [100_002_250_000_000, Date.civil(2011, 3,28)],
                                [100_002_500_000_000, Date.civil(2011, 6, 4)],
                                [100_002_750_000_000, Date.civil(2011, 8,10)],
                                [100_003_000_000_000, Date.civil(2011,10,17)],
                                [100_003_250_000_000, Date.civil(2011,12,23)],
                                [100_003_500_000_000, Date.civil(2012, 2,22)],
                                [100_003_750_000_000, Date.civil(2012, 4,22)],
                                [100_004_000_000_000, Date.civil(2012, 5,31)] ]

      interpolation_samples.each do |uid, date|
        it "interpolates #{uid} to #{date}" do
          FacebookProfile.uid2joined_on(uid).should == date
        end
      end

    end


  end

  context 'trust scoring' do

    let!(:wolf_fp) { create(:wolf_facebook_profile) }

    before :all do
      VCR.use_cassette('facebook/wolf_about_me_and_lars_and_weidong', allow_playback_repeats: true) do
        wolf_fp.import_profile_and_network!([lars_uid,weidong_uid])
      end
    end

    it '#compute_profile_authenticity' do
      wolf_fp.stub_chain(:facebook_profile_uids,:count).and_return(386)
      wolf_fp.compute_profile_authenticity.should == 85
    end

    xit '#compute_trust_score' do
      wolf_fp.profile_authenticity = 85
      wolf_fp.compute_trust_score.should == 85
    end

  end

  context "engagements" do
    let!(:wolf_fp) { create(:wolf_facebook_profile) }

    before :all do
      VCR.use_cassette('facebook/wolf_about_me_and_lars_and_weidong', allow_playback_repeats: true) do
        wolf_fp.import_profile_and_network!([lars_uid,weidong_uid])
      end
      wolf_fp.compute_engagements
    end

    context 'photo_engagements' do
      it 'computes unique co-tagged count' do
        wolf_fp.photo_engagements['co_tags_uniques'].should == 19
      end

      it 'computes unique likes count' do
        wolf_fp.photo_engagements['likes_uniques'].should == 12
      end

      it 'computes unique commented count' do
        wolf_fp.photo_engagements['comments_uniques'].should == 5
      end

      it 'computes total co-tags count' do
        wolf_fp.photo_engagements['co_tags_total'].should == 41
      end

      it 'computes total likes count' do
        wolf_fp.photo_engagements['likes_total'].should == 13
      end

      it 'computes total comments count' do
        wolf_fp.photo_engagements['comments_total'].should == 5
      end

      it 'saves hash of actors for tags, excluding self.uid' do
        wolf_fp.photo_engagements['co_tagged_with'].keys.should =~ %w(100000438595847 100001239205614 1031110353 1656423339 516572943 528078050 541258410 593848707 608745888 625698267 626054704 651861838 656512960 660028928 669325271 676875788 695766745 745749751 782729534)
      end

      it 'saves hash of actors for likes, excluding self.uid' do
        wolf_fp.photo_engagements['liked_by'].keys.should =~ %w(100000058337686 100001685490896 1043526773 519131475 543570782 587635458 663164967 695766745 710960310 713700928 734007489 872735293)
      end

      it 'saves hash of actors for comments, excluding self.uid' do
        wolf_fp.photo_engagements['commented_by'].keys.should =~ %w(528078050 543570782 570617660 630150873 669325271)
      end
    end

    context 'status_engagements' do
      it 'computes unique co-tagged count' do
        wolf_fp.status_engagements['co_tags_uniques'].should == 0
      end

      it 'computes unique likes count' do
        wolf_fp.status_engagements['likes_uniques'].should == 17
      end

      it 'computes unique commented count' do
        wolf_fp.status_engagements['comments_uniques'].should == 15
      end

      it 'computes total co-tags count' do
        wolf_fp.status_engagements['co_tags_total'].should == 0
      end

      it 'computes total likes count' do
        wolf_fp.status_engagements['likes_total'].should == 19
      end

      it 'computes total comments count' do
        wolf_fp.status_engagements['comments_total'].should == 16
      end

      it 'saves hash of actors for tags, excluding self.uid' do
        wolf_fp.status_engagements['co_tagged_with'].keys.should be_empty
      end

      it 'saves hash of actors for likes, excluding self.uid' do
        wolf_fp.status_engagements['liked_by'].keys.should =~ %w(524888626
                                                                 560982997
                                                                 832020470
                                                                 100002097933898
                                                                 2514847
                                                                 1173721181
                                                                 1518664569
                                                                 750445151
                                                                 208102217
                                                                 1245602573
                                                                 650931866
                                                                 1295192455
                                                                 1525875763
                                                                 10127062
                                                                 695005287
                                                                 656512960
                                                                 615925793)
      end

      it 'saves hash of actors for comments, excluding self.uid' do
        wolf_fp.status_engagements['commented_by'].keys.should =~ %w( 832020470
                                                                      503484735
                                                                      710238115
                                                                      100000058647979
                                                                      641972802
                                                                      521041796
                                                                      1213494587
                                                                      1219906970
                                                                      504949372
                                                                      541258410
                                                                      583780906
                                                                      650931866
                                                                      652163311
                                                                      765919154
                                                                      782729534 )
      end
    end
  end



  context '#collect_friends_location_stats' do

    xit 'returns locations map from friends sorted by frequency' do
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