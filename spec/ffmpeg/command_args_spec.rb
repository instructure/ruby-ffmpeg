# frozen_string_literal: true

module FFMPEG
  describe CommandArgs do
    describe '.escape' do
      context 'when the value contains special characters' do
        it 'escapes the value' do
          expect(described_class.escape('a:b')).to eq("'a:b'")
          expect(described_class.escape('a;b')).to eq("'a;b'")
          expect(described_class.escape('a|b')).to eq("'a|b'")
          expect(described_class.escape('a\\b')).to eq("'a\\\\b'")
          expect(described_class.escape("a'b")).to eq("'a\\'b'")
        end
      end

      context 'when the value does not contain special characters' do
        it 'does not escape the value' do
          expect(described_class.escape('ab')).to eq('ab')
        end
      end
    end
  end
end
