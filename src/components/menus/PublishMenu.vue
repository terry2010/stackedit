<template>
  <div class="side-bar__panel side-bar__panel--menu">
    <div class="side-bar__info" v-if="isCurrentTemp">
      <p><b>{{currentFileName}}</b> can not be published as it's a temporary file.</p>
    </div>
    <div v-else>
      <div class="side-bar__info" v-if="noToken">
        <p>You have to <b>link an account</b> to start publishing files.</p>
      </div>
      <div class="side-bar__info" v-if="publishLocations.length">
        <p><b>{{currentFileName}}</b> is already published.</p>
        <menu-entry @click.native="requestPublish">
          <icon-upload slot="icon"></icon-upload>
          <div>Publish now</div>
          <span>Update current file publications.</span>
        </menu-entry>
        <menu-entry @click.native="managePublish">
          <icon-view-list slot="icon"></icon-view-list>
          <div><div class="menu-entry__label menu-entry__label--count">{{locationCount}}</div> File publication</div>
          <span>Manage current file publication locations.</span>
        </menu-entry>
      </div>
      <hr>
       
       
       
      <div v-for="token in gitlabTokens" :key="token.sub">
        <menu-entry @click.native="publishGitlab(token)">
          <icon-provider slot="icon" provider-id="gitlab"></icon-provider>
          <div>Publish to GitLab</div>
          <span>{{token.name}}</span>
        </menu-entry>
      </div>
       
       
      <div v-for="token in zendeskTokens" :key="token.sub">
        <menu-entry @click.native="publishZendesk(token)">
          <icon-provider slot="icon" provider-id="zendesk"></icon-provider>
          <div>Publish to Zendesk Help Center</div>
          <span>{{token.name}} — {{token.subdomain}}</span>
        </menu-entry>
      </div>
      <hr>
      
      <menu-entry @click.native="addGitlabAccount">
        <icon-provider slot="icon" provider-id="gitlab"></icon-provider>
        <span>Add GitLab account</span>
      </menu-entry>
      
      <menu-entry @click.native="addZendeskAccount">
        <icon-provider slot="icon" provider-id="zendesk"></icon-provider>
        <span>Add Zendesk account</span>
      </menu-entry>
    </div>
  </div>
</template>

<script>
import { mapState, mapGetters } from 'vuex';
import MenuEntry from './common/MenuEntry';
import googleHelper from '../../services/providers/helpers/googleHelper';
import dropboxHelper from '../../services/providers/helpers/dropboxHelper';
import githubHelper from '../../services/providers/helpers/githubHelper';
import gitlabHelper from '../../services/providers/helpers/gitlabHelper';
import wordpressHelper from '../../services/providers/helpers/wordpressHelper';
import zendeskHelper from '../../services/providers/helpers/zendeskHelper';
import publishSvc from '../../services/publishSvc';
import store from '../../store';

const tokensToArray = (tokens, filter = () => true) => Object.values(tokens)
  .filter(token => filter(token))
  .sort((token1, token2) => token1.name.localeCompare(token2.name));

const publishModalOpener = type => async (token) => {
  try {
    const publishLocation = await store.dispatch('modal/open', {
      type,
      token,
    });
    publishSvc.createPublishLocation(publishLocation);
  } catch (e) { /* cancel */ }
};

export default {
  components: {
    MenuEntry,
  },
  computed: {
    ...mapState('queue', [
      'isPublishRequested',
    ]),
    ...mapGetters('file', [
      'isCurrentTemp',
    ]),
    ...mapGetters('publishLocation', {
      publishLocations: 'current',
    }),
    locationCount() {
      return Object.keys(this.publishLocations).length;
    },
    currentFileName() {
      return store.getters['file/current'].name;
    },
    bloggerTokens() {
      return tokensToArray(store.getters['data/googleTokensBySub'], token => token.isBlogger);
    },
    dropboxTokens() {
      return tokensToArray(store.getters['data/dropboxTokensBySub']);
    },
    githubTokens() {
      return tokensToArray(store.getters['data/githubTokensBySub']);
    },
    gitlabTokens() {
      return tokensToArray(store.getters['data/gitlabTokensBySub']);
    },
    googleDriveTokens() {
      return tokensToArray(store.getters['data/googleTokensBySub'], token => token.isDrive);
    },
    wordpressTokens() {
      return tokensToArray(store.getters['data/wordpressTokensBySub']);
    },
    zendeskTokens() {
      return tokensToArray(store.getters['data/zendeskTokensBySub']);
    },
    noToken() {
      return Object.values(store.getters['data/tokensByType'])
        .every(tokens => !Object.keys(tokens).length);
    },
  },
  methods: {
    requestPublish() {
      if (!this.isPublishRequested) {
        publishSvc.requestPublish();
      }
    },
    async managePublish() {
      try {
        await store.dispatch('modal/open', 'publishManagement');
      } catch (e) { /* cancel */ }
    },
    async addBloggerAccount() {
      try {
        await googleHelper.addBloggerAccount();
      } catch (e) { /* cancel */ }
    },
    async addDropboxAccount() {
      try {
        await store.dispatch('modal/open', { type: 'dropboxAccount' });
        await dropboxHelper.addAccount(!store.getters['data/localSettings'].dropboxRestrictedAccess);
      } catch (e) { /* cancel */ }
    },
    async addGithubAccount() {
      try {
        await store.dispatch('modal/open', { type: 'githubAccount' });
        await githubHelper.addAccount(store.getters['data/localSettings'].githubRepoFullAccess);
      } catch (e) { /* cancel */ }
    },
    async addGitlabAccount() {
      try {
        const { serverUrl, applicationId } = await store.dispatch('modal/open', { type: 'gitlabAccount' });
        await gitlabHelper.addAccount(serverUrl, applicationId);
      } catch (e) { /* cancel */ }
    },
    async addGoogleDriveAccount() {
      try {
        await store.dispatch('modal/open', { type: 'googleDriveAccount' });
        await googleHelper.addDriveAccount(!store.getters['data/localSettings'].googleDriveRestrictedAccess);
      } catch (e) { /* cancel */ }
    },
    async addWordpressAccount() {
      try {
        await wordpressHelper.addAccount();
      } catch (e) { /* cancel */ }
    },
    async addZendeskAccount() {
      try {
        const { subdomain, clientId } = await store.dispatch('modal/open', { type: 'zendeskAccount' });
        await zendeskHelper.addAccount(subdomain, clientId);
      } catch (e) { /* cancel */ }
    },
    publishBlogger: publishModalOpener('bloggerPublish'),
    publishBloggerPage: publishModalOpener('bloggerPagePublish'),
    publishDropbox: publishModalOpener('dropboxPublish'),
    publishGithub: publishModalOpener('githubPublish'),
    publishGist: publishModalOpener('gistPublish'),
    publishGitlab: publishModalOpener('gitlabPublish'),
    publishGoogleDrive: publishModalOpener('googleDrivePublish'),
    publishWordpress: publishModalOpener('wordpressPublish'),
    publishZendesk: publishModalOpener('zendeskPublish'),
  },
};
</script>
