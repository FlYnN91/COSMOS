# encoding: ascii-8bit

# Copyright 2014 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt

require 'spec_helper'
require 'cosmos'
require 'cosmos/packets/structure_item'

module Cosmos

  describe StructureItem do

    describe "name=" do
      it "should create new structure items" do
        StructureItem.new("test", 0, 8, :UINT, :BIG_ENDIAN, nil).name.should eql "test"
      end

      it "should complain about non String names" do
        expect { StructureItem.new(nil, 0, 8, :UINT, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "name must be a String but is a NilClass")
        expect { StructureItem.new(5, 0, 8, :UINT, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "name must be a String but is a Fixnum")
      end

      it "should complain about blank names" do
        expect { StructureItem.new("", 0, 8, :UINT, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "name must contain at least one character")
      end
    end

    describe "endianness=" do
      it "should accept BIG_ENDIAN and LITTLE_ENDIAN" do
        StructureItem.new("test", 0, 8, :UINT, :BIG_ENDIAN, nil).endianness.should eql :BIG_ENDIAN
        StructureItem.new("test", 0, 8, :UINT, :LITTLE_ENDIAN, nil).endianness.should eql :LITTLE_ENDIAN
      end

      it "should complain about bad endianness" do
        expect { StructureItem.new("test", 0, 8, :UINT, :BLAH, nil) }.to raise_error(ArgumentError, "test: unknown endianness: BLAH - Must be :BIG_ENDIAN or :LITTLE_ENDIAN")
      end
    end

    describe "data_type=" do
      it "should accept INT, UINT, FLOAT, STRING, BLOCK, and DERIVED data types" do
        %w(INT UINT FLOAT STRING BLOCK).each do |type|
          StructureItem.new("test", 0, 32, type.to_sym, :BIG_ENDIAN, nil).data_type.should eql type.to_sym
        end
        StructureItem.new("test", 0, 0, :DERIVED, :BIG_ENDIAN, nil).data_type.should eql :DERIVED
      end

      it "should complain about bad data types" do
        expect { StructureItem.new("test", 0, 0, :UNKNOWN, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "test: unknown data_type: UNKNOWN - Must be :INT, :UINT, :FLOAT, :STRING, :BLOCK, or :DERIVED")
      end
    end

    describe "overflow=" do
      it "should accept ERROR, ERROR_ALLOW_HEX, TRUNCATE and SATURATE overflow types" do
        %w(ERROR ERROR_ALLOW_HEX TRUNCATE SATURATE).each do |type|
          StructureItem.new("test", 0, 32, :INT, :BIG_ENDIAN, nil, type.to_sym).overflow.should eql type.to_sym
        end
      end

      it "should complain about bad overflow types" do
        expect { StructureItem.new("test", 0, 32, :INT, :BIG_ENDIAN, nil, :UNKNOWN) }.to raise_error(ArgumentError, "test: unknown overflow type: UNKNOWN - Must be :ERROR, :ERROR_ALLOW_HEX, :TRUNCATE, or :SATURATE")
      end
    end

    describe "bit_offset=" do
      it "should compain about bad bit offsets types" do
        expect { StructureItem.new("test", nil, 8, :UINT, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "test: bit_offset must be a Fixnum")
      end

      it "should complain about unaligned bit offsets" do
        %w(FLOAT STRING BLOCK).each do |type|
          expect { StructureItem.new("test", 1, 32, type.to_sym, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "test: bit_offset for :FLOAT, :STRING, and :BLOCK items must be byte aligned")
        end
      end

      it "should complain about non zero DERIVED bit offsets" do
        expect { StructureItem.new("test", 8, 0, :DERIVED, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "test: DERIVED items must have bit_offset of zero")
      end
    end

    describe "bit_size=" do
      it "should complain about bad bit sizes types" do
        expect { StructureItem.new("test", 0, nil, :UINT, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "test: bit_size must be a Fixnum")
      end

      it "should complain about 0 size INT, UINT, and FLOAT" do
        %w(INT UINT FLOAT).each do |type|
          expect { StructureItem.new("test", 0, 0, type.to_sym, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "test: bit_size cannot be negative or zero for :INT, :UINT, and :FLOAT items: 0")
        end
      end

      it "should complain about bad float bit sizes" do
        expect { StructureItem.new("test", 0, 8, :FLOAT, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "test: bit_size for FLOAT items must be 32 or 64. Given: 8")
      end

      it "should create 32 and 64 bit floats" do
        StructureItem.new("test", 0, 32, :FLOAT, :BIG_ENDIAN, nil).bit_size.should eql 32
        StructureItem.new("test", 0, 64, :FLOAT, :BIG_ENDIAN, nil).bit_size.should eql 64
      end

      it "should complain about non zero DERIVED bit sizes" do
        expect { StructureItem.new("test", 0, 8, :DERIVED, :BIG_ENDIAN, nil) }.to raise_error(ArgumentError, "test: DERIVED items must have bit_size of zero")
      end
    end

    describe "array_size=" do
      it "should complain about bad array size types" do
        expect { StructureItem.new("test", 0, 8, :UINT, :BIG_ENDIAN, "") }.to raise_error(ArgumentError, "test: array_size must be a Fixnum")
      end

      it "should complain about array size != multiple of bit size" do
        expect { StructureItem.new("test", 0, 8, :UINT, :BIG_ENDIAN, 10) }.to raise_error(ArgumentError, "test: array_size must be a multiple of bit_size")
      end

      it "should not complain about array size != multiple of bit size with negative array size" do
        expect { StructureItem.new("test", 0, 32, :UINT, :BIG_ENDIAN, -8) }.not_to raise_error
      end
    end

    describe "<=>" do
      it "should sort items according to positive bit offset" do
        si1 = StructureItem.new("si1", 0, 8, :UINT, :BIG_ENDIAN, nil)
        si2 = StructureItem.new("si2", 8, 8, :UINT, :BIG_ENDIAN, nil)
        (si1 < si2).should be_truthy
        (si1 == si2).should be_falsey
        (si1 > si2).should be_falsey

        si2 = StructureItem.new("si2", 0, 8, :UINT, :BIG_ENDIAN, nil)
        (si1 < si2).should be_falsey
        (si1 == si2).should be_truthy
        (si1 > si2).should be_falsey
      end

      it "should sort items with 0 bit offset according to bit size" do
        si1 = StructureItem.new("si1", 0, 8, :UINT, :BIG_ENDIAN, nil)
        si2 = StructureItem.new("si2", 0, 0, :BLOCK, :BIG_ENDIAN, nil)
        (si1 < si2).should be_falsey
        (si1 == si2).should be_falsey
        (si1 > si2).should be_truthy
      end

      it "should sort items according to negative bit offset" do
        si1 = StructureItem.new("si1", -8, 8, :UINT, :BIG_ENDIAN, nil)
        si2 = StructureItem.new("si2", -16, 8, :UINT, :BIG_ENDIAN, nil)
        (si1 < si2).should be_falsey
        (si1 == si2).should be_falsey
        (si1 > si2).should be_truthy

        si2 = StructureItem.new("si2", -8, 8, :UINT, :BIG_ENDIAN, nil)
        (si1 < si2).should be_falsey
        # si1 == si2 even though they have different names and sizes
        (si1 == si2).should be_truthy
        (si1 > si2).should be_falsey
      end

      it "should sort items according to mixed bit offset" do
        si1 = StructureItem.new("si1", 16, 8, :UINT, :BIG_ENDIAN, nil)
        si2 = StructureItem.new("si2", -8, 8, :UINT, :BIG_ENDIAN, nil)
        (si1 < si2).should be_truthy
        (si1 == si2).should be_falsey
        (si1 > si2).should be_falsey
      end
    end

    describe "clone" do
      it "should duplicate the entire structure item " do
        si1 = StructureItem.new("si1", -8, 1, :UINT, :LITTLE_ENDIAN, nil)
        si2 = si1.clone
        (si1 == si2).should be_truthy
      end
    end

    describe "to_hash" do
      it "should create a Hash" do
        item = StructureItem.new("test", 0, 8, :UINT, :BIG_ENDIAN, 16)
        hash = item.to_hash
        hash.keys.length.should eql 7
        hash.keys.should include('name','bit_offset','bit_size','data_type','endianness','array_size', 'overflow')
        hash["name"].should eql "test"
        hash["bit_offset"].should eql 0
        hash["bit_size"].should eql 8
        hash["data_type"].should eql :UINT
        hash["endianness"].should eql :BIG_ENDIAN
        hash["array_size"].should eql 16
        hash["overflow"].should eql :ERROR
      end
    end

  end
end