require "insights/api/common/graphql"

RSpec.describe Insights::API::Common::GraphQL, :type => :request do
  let!(:graphql_endpoint) { "/api/v1.0/graphql" }

  let!(:ext_tenant)   { rand(1000).to_s }
  let!(:tenant)       { Tenant.create!(:name => "tenant_a", :external_tenant => ext_tenant) }
  let!(:identity)     { Base64.encode64({'identity' => { 'account_number' => ext_tenant }}.to_json) }
  let!(:headers)      { { "CONTENT_TYPE" => "application/json", "x-rh-identity" => identity } }

  let!(:source_typeR) { SourceType.create(:name => "rhev_sample", :product_name => "RedHat Virtualization", :vendor => "redhat") }
  let!(:source_typeV) { SourceType.create(:name => "vmware_sample", :product_name => "VmWare vCenter", :vendor => "vmware") }
  let!(:source_typeO) { SourceType.create(:name => "openstack_sample", :product_name => "OpenStack", :vendor => "redhat") }

  let!(:source_a1)    { Source.create!(:tenant => tenant, :uid => "1", :name => "source_a1", :source_type => source_typeR) }
  let!(:source_a2)    { Source.create!(:tenant => tenant, :uid => "2", :name => "source_a2", :source_type => source_typeR) }
  let!(:source_b1)    { Source.create!(:tenant => tenant, :uid => "3", :name => "source_b1", :source_type => source_typeR) }
  let!(:source_b2)    { Source.create!(:tenant => tenant, :uid => "4", :name => "source_b2", :source_type => source_typeR) }
  let!(:source_b3)    { Source.create!(:tenant => tenant, :uid => "5", :name => "source_b3", :source_type => source_typeR) }

  let!(:endpoint_a21) { Endpoint.create!(:tenant => tenant, :source => source_a2, :host => "source_a2.example.com", :port => "121", :role => "web_lb1") }
  let!(:endpoint_a22) { Endpoint.create!(:tenant => tenant, :source => source_a2, :host => "source_a2.example.com", :port => "122", :role => "web_lb2") }
  let!(:endpoint_a23) { Endpoint.create!(:tenant => tenant, :source => source_a2, :host => "source_a2.example.com", :port => "123", :role => "web_lb3") }

  let!(:endpoint_b21) { Endpoint.create!(:tenant => tenant, :source => source_b2, :host => "source_b2.example.com", :port => "221", :role => "web_lb1") }
  let!(:endpoint_b22) { Endpoint.create!(:tenant => tenant, :source => source_b2, :host => "source_b2.example.com", :port => "222", :role => "web_lb2") }
  let!(:endpoint_b23) { Endpoint.create!(:tenant => tenant, :source => source_b2, :host => "source_b2.example.com", :port => "223", :role => "web_lb3") }

  let!(:auth_a221)    { Authentication.create!(:tenant => tenant, :resource => endpoint_a22, :authtype => "userpassword", :username => "admin", :password => "secret") }
  let!(:auth_a222)    { Authentication.create!(:tenant => tenant, :resource => endpoint_a22, :authtype => "token") }

  let!(:auth_b221)    { Authentication.create!(:tenant => tenant, :resource => endpoint_b22, :authtype => "userpassword", :username => "admin", :password => "secret") }
  let!(:auth_b222)    { Authentication.create!(:tenant => tenant, :resource => endpoint_b22, :authtype => "token") }

  context "querying sources" do
    before { stub_const("ENV", "BYPASS_TENANCY" => nil) }

    it "with no offset or limit returns all sources" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources {
            uid
            name
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "uid": "1",
              "name": "source_a1"
            },
            {
              "uid": "2",
              "name": "source_a2"
            },
            {
              "uid": "3",
              "name": "source_b1"
            },
            {
              "uid": "4",
              "name": "source_b2"
            },
            {
              "uid": "5",
              "name": "source_b3"
            }
          ]
        }'))
    end

    it "honors limit parameter" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources(limit: 2) {
            uid
            name
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "uid": "1",
              "name": "source_a1"
            },
            {
              "uid": "2",
              "name": "source_a2"
            }
          ]
        }'))
    end

    it "honors offset parameter" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources(offset: 1) {
            uid
            name
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "uid": "2",
              "name": "source_a2"
            },
            {
              "uid": "3",
              "name": "source_b1"
            },
            {
              "uid": "4",
              "name": "source_b2"
            },
            {
              "uid": "5",
              "name": "source_b3"
            }
          ]
        }'))
    end

    it "honors offset and limit parameter" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources(offset: 1, limit: 2) {
            uid
            name
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "uid": "2",
              "name": "source_a2"
            },
            {
              "uid": "3",
              "name": "source_b1"
            }
          ]
        }'))
    end

    it "honors filter parameter" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources(filter: { name: { starts_with: "source_b"}}) {
            name
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_b1"
            },
            {
              "name": "source_b2"
            },
            {
              "name": "source_b3"
            }
          ]
        }'))
    end

    it "honors filter and limit parameter" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources(filter: { name: { ends_with: "2"}}, limit: 1) {
            name
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_a2"
            }
          ]
        }'))
    end

    it "honors filter with offset and limit parameter" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources(filter: { name: { starts_with: "source_b"}}, offset: 1, limit: 1) {
            name
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_b2"
            }
          ]
        }'))
    end
  end

  context "supports result sorting" do
    before { stub_const("ENV", "BYPASS_TENANCY" => nil) }

    it "via sort_by with a single attribute" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          source_types(filter: { name: { ends_with: "sample" } }, sort_by: "vendor") {
            vendor
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]["source_types"].collect { |st| st["vendor"] })
        .to eq(%w[redhat redhat vmware])
    end

    it "via sort_by with a single attribute in descending order" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          source_types(filter: { name: { ends_with: "sample" } }, sort_by: "vendor:desc") {
            vendor
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]["source_types"].collect { |st| st["vendor"] })
        .to eq(%w[vmware redhat redhat])
    end

    it "via sort_by with a multiple attributes in mixed order" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          source_types(filter: { name: { ends_with: "sample" } }, sort_by: ["vendor", "product_name:desc"]) {
            vendor
            product_name
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]["source_types"].collect { |st| [st["vendor"], st["product_name"]] })
        .to eq([["redhat", "RedHat Virtualization"], ["redhat", "OpenStack"], ["vmware", "VmWare vCenter"]])
    end
  end

  context "querying multiple collections" do
    before { stub_const("ENV", "BYPASS_TENANCY" => nil) }

    it "with no offset or limit returns all resources" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources {
            name
          },
          endpoints {
            host
            port
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_a1"
            },
            {
              "name": "source_a2"
            },
            {
              "name": "source_b1"
            },
            {
              "name": "source_b2"
            },
            {
              "name": "source_b3"
            }
          ],
          "endpoints": [
            {
              "host": "source_a2.example.com",
              "port": "121"
            },
            {
              "host": "source_a2.example.com",
              "port": "122"
            },
            {
              "host": "source_a2.example.com",
              "port": "123"
            },
            {
              "host": "source_b2.example.com",
              "port": "221"
            },
            {
              "host": "source_b2.example.com",
              "port": "222"
            },
            {
              "host": "source_b2.example.com",
              "port": "223"
            }
          ]
        }'))
    end

    it "honors separate offset and limit" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources(offset: 1, limit: 3) {
            name
          },
          endpoints(offset: 3, limit: 2) {
            host
            port
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_a2"
            },
            {
              "name": "source_b1"
            },
            {
              "name": "source_b2"
            }
          ],
          "endpoints": [
            {
              "host": "source_b2.example.com",
              "port": "221"
            },
            {
              "host": "source_b2.example.com",
              "port": "222"
            }
          ]
        }'))
    end

    it "honors separate filter, offset and limit" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources(filter: { name: { starts_with: "source_b" } }, offset: 1, limit: 1) {
            name
          },
          endpoints(filter: { host: { eq: "source_a2.example.com" } }, limit: 2) {
            host
            port
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_b2"
            }
          ],
          "endpoints": [
            {
              "host": "source_a2.example.com",
              "port": "121"
            },
            {
              "host": "source_a2.example.com",
              "port": "122"
            }
          ]
        }'))
    end
  end

  context "filtering on associations" do
    before do
      stub_const("ENV", "BYPASS_TENANCY" => nil)

      rhev      = SourceType.create(:name => "filtered_rhev",      :product_name => "RedHat Virtualization", :vendor => "redhat")
      openstack = SourceType.create(:name => "filtered_openstack", :product_name => "OpenStack",             :vendor => "redhat")
      openshift = SourceType.create(:name => "filtered_openshift", :product_name => "OpenShift",             :vendor => "redhat")

      Source.create!(:name => "rhev_source_sample",      :tenant => tenant, :source_type => rhev)
      Source.create!(:name => "openstack_source_sample", :tenant => tenant, :source_type => openstack)
      Source.create!(:name => "openshift_source_sample", :tenant => tenant, :source_type => openshift)
    end

    it("succeeds on a single association attribute value") do
      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { source_type: { name: { eq: "filtered_rhev"}}}) {
            name
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "rhev_source_sample"
            }
          ]
        }'))
    end

    it("succeeds with multiple association attribute values") do
      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { source_type: { name: { eq: ["filtered_openstack", "filtered_openshift"]}}}) {
            name
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "openstack_source_sample"
            },
            {
              "name": "openshift_source_sample"
            }
          ]
        }'))
    end
  end

  context "querying associations" do
    before { stub_const("ENV", "BYPASS_TENANCY" => nil) }

    it "honors one-off associations" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources(filter: { name: { starts_with: "source_b" } }) {
            name
            endpoints {
              host
              port
              role
            }
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_b1",
              "endpoints": []
            },
            {
              "name": "source_b2",
              "endpoints": [
                {
                  "host": "source_b2.example.com",
                  "port": "221",
                  "role": "web_lb1"
                },
                {
                  "host": "source_b2.example.com",
                  "port": "222",
                  "role": "web_lb2"
                },
                {
                  "host": "source_b2.example.com",
                  "port": "223",
                  "role": "web_lb3"
                }
              ]
            },
            {
              "name": "source_b3",
              "endpoints": []
            }
          ]
        }'))
    end

    it "honors one-off associations with different offset and limit" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          sources(filter: { name: { starts_with: "source_b" } }, offset: 1, limit: 1) {
            name
            endpoints(offset: 0, limit: 2) {
              host
              port
              role
            }
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_b2",
              "endpoints": [
                {
                  "host": "source_b2.example.com",
                  "port": "221",
                  "role": "web_lb1"
                },
                {
                  "host": "source_b2.example.com",
                  "port": "222",
                  "role": "web_lb2"
                }
              ]
            }
          ]
        }'))
    end

    it "honors 2-level associations" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          source_types(filter: {name: {eq: ["rhev_sample", "vmware_sample"]}}) {
            vendor
            product_name
            sources {
              name
              endpoints {
                host
                port
                role
              }
            }
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "source_types": [
            {
              "vendor": "redhat",
              "product_name": "RedHat Virtualization",
              "sources": [
                {
                  "name": "source_a1",
                  "endpoints": []
                },
                {
                  "name": "source_a2",
                  "endpoints": [
                    {
                      "host": "source_a2.example.com",
                      "port": "121",
                      "role": "web_lb1"
                    },
                    {
                      "host": "source_a2.example.com",
                      "port": "122",
                      "role": "web_lb2"
                    },
                    {
                      "host": "source_a2.example.com",
                      "port": "123",
                      "role": "web_lb3"
                    }
                  ]
                },
                {
                  "name": "source_b1",
                  "endpoints": []
                },
                {
                  "name": "source_b2",
                  "endpoints": [
                    {
                      "host": "source_b2.example.com",
                      "port": "221",
                      "role": "web_lb1"
                    },
                    {
                      "host": "source_b2.example.com",
                      "port": "222",
                      "role": "web_lb2"
                    },
                    {
                      "host": "source_b2.example.com",
                      "port": "223",
                      "role": "web_lb3"
                    }
                  ]
                },
                {
                  "name": "source_b3",
                  "endpoints": []
                }
              ]
            },
            {
              "vendor": "vmware",
              "product_name": "VmWare vCenter",
              "sources": []
            }
          ]
        }'))
    end

    it "honors 3-level associations" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          source_types(filter: {vendor: {eq: "redhat"}}) {
            vendor
            product_name
            sources {
              name
              endpoints {
                host
                port
                role
                authentications {
                  authtype
                  username
                }
              }
            }
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "source_types": [
            {
              "vendor": "redhat",
              "product_name": "RedHat Virtualization",
              "sources": [
                {
                  "name": "source_a1",
                  "endpoints": []
                },
                {
                  "name": "source_a2",
                  "endpoints": [
                    {
                      "host": "source_a2.example.com",
                      "port": "121",
                      "role": "web_lb1",
                      "authentications": []
                    },
                    {
                      "host": "source_a2.example.com",
                      "port": "122",
                      "role": "web_lb2",
                      "authentications": [
                        {
                          "authtype": "userpassword",
                          "username": "admin"
                        },
                        {
                          "authtype": "token",
                          "username": null
                        }
                      ]
                    },
                    {
                      "host": "source_a2.example.com",
                      "port": "123",
                      "role": "web_lb3",
                      "authentications": []
                    }
                  ]
                },
                {
                  "name": "source_b1",
                  "endpoints": []
                },
                {
                  "name": "source_b2",
                  "endpoints": [
                    {
                      "host": "source_b2.example.com",
                      "port": "221",
                      "role": "web_lb1",
                      "authentications": []
                    },
                    {
                      "host": "source_b2.example.com",
                      "port": "222",
                      "role": "web_lb2",
                      "authentications": [
                        {
                          "authtype": "userpassword",
                          "username": "admin"
                        },
                        {
                          "authtype": "token",
                          "username": null
                        }
                      ]
                    },
                    {
                      "host": "source_b2.example.com",
                      "port": "223",
                      "role": "web_lb3",
                      "authentications": []
                    }
                  ]
                },
                {
                  "name": "source_b3",
                  "endpoints": []
                }
              ]
            },
            {
              "vendor": "redhat",
              "product_name": "OpenStack",
              "sources": []
            }
          ]
        }'))
    end
  end

  context "querying authentications" do
    before { stub_const("ENV", "BYPASS_TENANCY" => nil) }

    it "must return an error if asking for encrypted attributes" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          authentications {
            authtype
            username
            password
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to be_nil
      expect(response.parsed_body["errors"].first["message"]).to match("Field 'password' doesn't exist on type 'Authentication'")
    end
  end
end
