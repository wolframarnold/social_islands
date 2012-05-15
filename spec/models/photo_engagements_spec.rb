require 'spec_helper'

describe PhotoEngagements do

  let(:fp) {FactoryGirl.create(:facebook_profile)}

  context '#compute_photo_engagements' do

    it 'records an entry' do
      expect {
        fp.compute_photo_engagements
        fp.save
      }.should change{fp.photo_engagements.present?}.from(false).to(true)
    end

    context 'attributes and aggregates' do

      before do
        fp.photos[0]['comments']['data'] << {"id" => "10150701778989412_6371457",
                                             "from" => {"name" => "Yannis Adoniou's KUNST-STOFF",
                                                        "category" => "Non-profit organization",
                                                        "id" => "40981764411"},
                                             "message" => "Another comment, same person",
                                             "created_time" => "2012-04-19T07:13:47+0000"}
        @eng = fp.build_photo_engagements.compute
        fp.save
      end

      it 'copies the uid' do
        @eng.uid.should == fp.uid
      end

      it "copies the user's name" do
        @eng.name.should == fp.name
      end

      it 'computes unique co-tagged count' do
        @eng.co_tags_uniques.should == 4  # two photos tagged with 2 friends each
      end

      it 'computes unique liked count' do
        @eng.likes_uniques.should == 24 + 9  # for the two photos, respectively
      end

      it 'computes unique commented count' do
        @eng.comments_uniques.should == 7 + 1  # for the two photos, respectively, excluding self
      end

      it 'computes total co-tags count' do
        @eng.co_tags_total.should == 4  # two photos tagged with 2 friends each

      end

      it 'computes total likes count' do
        @eng.likes_total.should == 24 + 9  # for the two photos, respectively

      end

      it 'computes total comments count' do
        @eng.comments_total.should == 7 + 1 + 1 # one more, for 2nd comment
      end

      it 'saves hash of actors for tags, excluding self.uid' do
        @eng.co_tagged_with.keys.should =~ %w(589356473 558293791 568794740 617287785)
      end

      it 'saves hash of actors for likes, excluding self.uid' do
        @eng.liked_by.keys.should =~ %w(13005165
                                        100002047432823
                                        1356153138
                                        527391410
                                        655317879
                                        1374922097
                                        100001224767136
                                        100000241077339
                                        1616917040
                                        620296780
                                        1200597914
                                        755494517
                                        697597360
                                        1060735738
                                        605639397
                                        1006354328
                                        1023085608
                                        1349795215
                                        678314575
                                        683976322
                                        541653582
                                        100002217497819
                                        545153726
                                        100003699763655
                                        610867332
                                        598322650
                                        540535876
                                        100000026271587
                                        667152122
                                        544993696
                                        1625671516
                                        629330868
                                        1269520910)
      end

      it 'saves hash of actors for comments, excluding self.uid' do
        @eng.commented_by.keys.should =~ %w(40981764411
                                            100002217497819
                                            504517003
                                            500384038
                                            1006354328
                                            100001224767136
                                            100002047432823
                                            540535876)
      end

    end

  end
end
