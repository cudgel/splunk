# frozen_string_literal: true

require 'spec_helper'

describe 'splunk::input' do
  let(:pre_condition) { 'include splunk' }
  let(:environment) { 'ci' }
  let(:title) { 'authlog' }
  let(:node) { 'test.ci' }
  let(:facts) do
    {
      'role'         => 'splunk_forwarder',
      'architecture' => 'x86_64',
      'kernel'       => 'Linux',
      'os'           => {
        'family'  => 'RedHat',
        'release' => {
          'major' => '6',
        },
      },
    }
  end
  let :default_params do
    {
      title: 'authlog',
      target: '/var/log/authlog',
      version: '7.2.1',
      release: 'be11b2c46e23',
    }
  end

  context 'with default options' do
    it { is_expected.to compile.with_all_deps }
  end
end
