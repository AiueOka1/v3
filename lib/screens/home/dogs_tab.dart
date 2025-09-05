import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/models/dog.dart';
import 'package:pawtech/providers/dog_provider.dart';
import 'package:pawtech/screens/dog/dog_details_screen.dart';
import 'package:pawtech/screens/dog/add_dog_screen.dart';
import 'package:pawtech/widgets/dog_list_item.dart';

class DogsTab extends StatefulWidget {
  const DogsTab({super.key});

  @override
  State<DogsTab> createState() => _DogsTabState();
}

class _DogsTabState extends State<DogsTab> {
  String _searchQuery = '';
  String _filterOption = 'All';

  @override
  Widget build(BuildContext context) {
    final dogProvider = Provider.of<DogProvider>(context);
    final allDogs = dogProvider.dogs;
    
    // Apply filters
    List<Dog> filteredDogs = allDogs;
    
    if (_filterOption == 'Active') {
      filteredDogs = allDogs.where((dog) => dog.isActive).toList();
    } else if (_filterOption == 'Inactive') {
      filteredDogs = allDogs.where((dog) => !dog.isActive).toList();
    }
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      filteredDogs = filteredDogs.where((dog) => 
        dog.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        dog.breed.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        dog.specialization.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return RefreshIndicator(
      onRefresh: () => dogProvider.fetchDogs(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Canine Units',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddDogScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Dog'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search dogs...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactive'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: dogProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No dogs found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AddDogScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Your First Dog'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDogs.length,
                        itemBuilder: (context, index) {
                          final dog = filteredDogs[index];
                          return DogListItem(
                            dog: dog,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DogDetailsScreen(dogId: dog.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterOption == label;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterOption = label;
        });
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }
}

