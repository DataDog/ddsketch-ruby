shared_context 'loaded gems' do |gems = {}|
  before do
    allow(Gem.loaded_specs).to receive(:[]).and_call_original

    gems.each do |gem_name, version|
      spec = nil

      unless version.nil?
        version = Gem::Version.new(version.to_s)
        spec = instance_double(
          Bundler::StubSpecification,
          version: version
        )
      end

      allow(Gem.loaded_specs).to receive(:[])
        .with(gem_name.to_s)
        .and_return(spec)
    end
  end
end
