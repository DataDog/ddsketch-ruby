RSpec.describe Datadog::DDSketch do
  describe "::protobuf_gem_loaded_successfully?" do
    subject { described_class.protobuf_gem_loaded_successfully? }

    context "when there is an protobuf gem loading issue" do
      before { allow(described_class).to receive(:protobuf_gem_loading_issue).and_return("Unsupported, sorry :(") }

      it { is_expected.to be false }
    end

    context "when there is no protobuf gem loading issue" do
      before { allow(described_class).to receive(:protobuf_gem_loading_issue).and_return(nil) }

      it { is_expected.to be true }
    end
  end

  describe "::protobuf_gem_loading_issue" do
    subject { described_class.protobuf_gem_loading_issue }

    context "when 'google-protobuf' is not available" do
      include_context "loaded gems", {"google-protobuf" => nil}

      before do
        hide_const("::Google::Protobuf")
      end

      it { is_expected.to include "Missing google-protobuf" }
    end

    context "when 'google-protobuf' is available but not yet loaded" do
      before do
        hide_const("::Google::Protobuf")
      end

      context "but is below the minimum version" do
        include_context "loaded gems", {"google-protobuf" => Gem::Version.new("2.9")}

        it { is_expected.to include "google-protobuf >= 3.0" }
      end

      context "and meeting the minimum version" do
        include_context "loaded gems", {"google-protobuf" => Gem::Version.new("3.0")}

        context "when protobuf does not load correctly" do
          before { allow(described_class).to receive(:protobuf_required_successfully?).and_return(false) }

          it { is_expected.to include "error loading" }
        end

        context "when protobuf loads successfully" do
          before { allow(described_class).to receive(:protobuf_required_successfully?).and_return(true) }

          it { is_expected.to be nil }
        end
      end
    end

    context "when 'google-protobuf' is already loaded" do
      before do
        stub_const("::Google::Protobuf", Module.new)
        allow(described_class).to receive(:protobuf_required_successfully?).and_return(true)
      end

      it { is_expected.to be nil }
    end
  end

  describe "::protobuf_required_successfully?" do
    subject { described_class.send(:protobuf_required_successfully?) }

    before do
      # NOTE: Be careful not to leave leftover state here
      #
      # Remove any previous state
      if described_class.instance_variable_defined?(:@protobuf_loaded)
        described_class.remove_instance_variable(:@protobuf_loaded)
      end

      allow(Kernel).to receive(:warn)
    end

    after do
      # Remove leftover state
      described_class.remove_instance_variable(:@protobuf_loaded)
    end

    context "when there is an issue requiring protobuf" do
      before { allow(described_class).to receive(:require).and_raise(LoadError.new("Simulated require failure")) }

      it { is_expected.to be false }

      it "logs a warning" do
        expect(Kernel).to receive(:warn).with(/Error while loading google-protobuf/)

        subject
      end
    end

    context "when requiring protobuf is successful" do
      before { allow(described_class).to receive(:require).and_return(true) }

      it { is_expected.to be true }
    end
  end
end
