import { Injectable } from '@angular/core';
import { Plugin, Cordova, IonicNativePlugin } from '@ionic-native/core';

@Plugin({
    pluginName: 'ChilFtp',
    plugin: 'cordova-plugin-chilftp',
    pluginRef: 'cordova.plugin.chilftp',
    repo: 'https://github.com/vlinde/cordova-plugin-chilftp',
    platforms: ['Android', 'iOS']
})
@Injectable()
export class ChilFtp extends IonicNativePlugin {

    @Cordova()
    connect(hostname: string, port: number, username: string, password: string, restartNext:boolean): Promise<any> { return; }

    @Cordova()
    asyncPutFile(local: string, remote: string): Promise<any> { return; }

    @Cordova()
    upload(local: string, remote: string): Promise<any> { return; }

    @Cordova()
    asyncGetFile(remote: string, local: string): Promise<any> { return; }

    @Cordova()
    download(remote: string, local: string): Promise<any> { return; }

    @Cordova()
    rename(path: string, existing_name: string, new_name: string, replace?: boolean): Promise<any> { return; }

    @Cordova()
    ls(remote: string): Promise<any> { return; }

    @Cordova()
    getRemoteFileSize(remoteFileName: string): Promise<any> { return; }

    @Cordova()
    changeRemoteDir(remoteDir: string): Promise<any> { return; }

    @Cordova()
    createRemoteDir(remoteNewDir: string) : Promise<any> { return; }

    @Cordova()
    deleteRemoteFile(remoteFileName: string): Promise<any> { return; }

    @Cordova()
    keySetting(key: string): Promise<any> { return; }

    @Cordova()
    disconnect() : Promise<any> { return; }

    @Cordova()
    abort(): Promise<any> { return; }

    @Cordova()
    getPathFromMediaUri(data: string): Promise<any> { return; }

    @Cordova()
    checkConnection(): Promise<any> { return; }

}
