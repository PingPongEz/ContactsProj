//
//  ContactsDemo.swift
//  ContactList
//
//  Created by Сергей Веретенников on 22/05/2022.
//

import SwiftUI
import CoreData

struct ContactsDemo: View {
    
    @Environment(\.managedObjectContext) private var context
    
    @State private var isSheetPresented = false
    @State private var isDeleteAlertPresented = false
    @State private var index = 0
    @State private var sortingContacts = ""
    
    var search: Binding<String> {
        Binding {
            sortingContacts
        } set: { newValue in
            sortingContacts = newValue
            
            guard !newValue.isEmpty else {
                contacts.nsPredicate = nil
                return
            }
            
            contacts.nsPredicate = NSPredicate(format: "name contains[cd] %@", newValue)
        }
    }
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Contact.name, ascending: true)],
        animation: .default
    )
    
    private var contacts: FetchedResults<Contact>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(contacts.indices, id: \.self) { index in
                    let cont = contacts[index]
                    Section(cont.name) {
                        NavigationLink {
                            InfoAboutContact(contact: cont)
                        } label: {
                            CellInTable(name: cont.secondName, number: cont.number)
                        }
                        .callDeleteSwipes(indexx: self.$index, callContact: callContact, index: index, isDeleteAlertPresented: $isDeleteAlertPresented)
                    }
                    .font(.system(size: 13))
                }
            }
            .searchable(text: search)
            .alert("Do you want to delete contact?", isPresented: $isDeleteAlertPresented, actions: {
                DeleteAlertButtons(action: deleteContact, index: self.index, isDeleteAlertPresented: $isDeleteAlertPresented)
            })
            .navigationTitle("My contacts")
            .toolbar {
                Button {
                    addContact()
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $isSheetPresented) {
                AddContactView(isPresented: $isSheetPresented)
            }
        }
    }
    
    private func callContact(offset: Int) {
        withAnimation(.easeOut) {
            let number = contacts[offset].number
            let callPhone = "tel://"
            let formatedCall = callPhone + number
            guard let url = URL(string: formatedCall) else { return }
            UIApplication.shared.open(url)
        }
    }
    
    private func addContact() {
        isSheetPresented.toggle()
    }
    
    private func deleteContact(offset: Int) {
        withAnimation {
            context.delete(contacts[offset])
            do {
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

struct ContactsDemo_Previews: PreviewProvider {
    static var previews: some View {
        ContactsDemo()
    }
}



struct DeleteAlertButtons: View {
    
    let action: (Int) -> Void
    let index: Int
    @Binding var isDeleteAlertPresented: Bool
    
    var body: some View {
        ZStack {
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    action(index)
                }
            }) {
                Text("Delete")
            }
            
            Button(action: { isDeleteAlertPresented.toggle() }) {
                Text("Cancel")
            }
        }
    }
}
