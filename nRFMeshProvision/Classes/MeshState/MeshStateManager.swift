//
//  MeshStateManager.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import UIKit

public class MeshStateManager: NSObject {
    
    public private (set) var meshState: MeshState!

    private override init() {
        super.init()
    }

    public init(withState aState: MeshState) {
        meshState = aState
    }
   
    public func state() -> MeshState {
        return meshState
    }

    public func saveState() {
        let encodedData = try? JSONEncoder().encode(meshState)
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                try encodedData!.write(to: fileURL)
            } catch {
                print(error)
            }
    }
   }
    
    public func restoreState() {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                let data = try Data(contentsOf: fileURL)
                let decodedState = try JSONDecoder().decode(MeshState.self, from: data)
                meshState = decodedState
            } catch {
                print("Error reading state from file")
            }
    }
   }

    public func deleteState() -> Bool {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            if FileManager.default.isDeletableFile(atPath: filePath) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    return true
                } catch {
                    print(error.localizedDescription)
                    return false
                }
            }
        }
        return false;
    }

    // MARK: - Static accessors
    public static func restoreState() -> MeshStateManager? {
        if MeshStateManager.stateExists() {
            let aStateManager = MeshStateManager()
            aStateManager.restoreState()
            return aStateManager
        } else {
            return nil
        }
        
    }

    public static func stateExists() -> Bool {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            return FileManager.default.fileExists(atPath: filePath)
        } else {
            return false
        }
    }
    
    public static func generateState() -> MeshStateManager {
        let aStateManager = MeshStateManager()
        let networkKey = generateNewKey()
        let keyIndex = Data([0x00, 0x00])
        let flags = Data([0x00])
        let ivIndex = Data([0x00, 0x00, 0x00, 0x00])
        let unicastAddress = Data([0x01, 0x23])
        let globalTTL: UInt8 = 5
        let networkName = "My Network"
        let appKeys = [["AppKey 1": generateNewKey()],
                       ["AppKey 2": generateNewKey()],
                       ["AppKey 3": generateNewKey()]]
        let state = MeshState(withNodeList: [], netKey: networkKey, keyIndex: keyIndex,
                              IVIndex: ivIndex, globalTTL: globalTTL, unicastAddress: unicastAddress,
                              flags: flags, appKeys: appKeys, andName: networkName)
        aStateManager.meshState = state
        aStateManager.saveState()
        return aStateManager
    }
    
    private static func getDocumentDirectory() -> String? {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }
    
    // MARK: - Generation helper
    static func generateNewKey() -> Data {
        let helper = OpenSSLHelper()
        let newKey = helper.generateRandom()
        return newKey!
    }
}
