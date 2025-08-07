import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const EditProductPage({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _categoryController;

  bool _isNegotiable = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final data = widget.productData;
    _isNegotiable = data.containsKey('startingPrice');

    _nameController = TextEditingController(text: data['name']);
    _priceController = TextEditingController(
      text: data[_isNegotiable ? 'startingPrice' : 'price'].toString(),
    );
    _quantityController = TextEditingController(text: data['quantity']);
    _categoryController = TextEditingController(text: data['category']);
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);

    try {
      final updateData = {
        'name': _nameController.text.trim(),
        'quantity': _quantityController.text.trim(),
        'category': _categoryController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_isNegotiable) {
        updateData['startingPrice'] = _priceController.text.trim();
        updateData.remove('price');
      } else {
        updateData['price'] = _priceController.text.trim();
        updateData.remove('startingPrice');
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Product updated successfully")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Product"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, "Product Name"),
              SizedBox(height: 12),
              _buildTextField(
                _priceController,
                _isNegotiable ? "Starting Price (₹)" : "Price (₹)",
                isNumber: true,
              ),
              SizedBox(height: 12),
              _buildTextField(_quantityController, "Quantity (e.g. 50kg)"),
              SizedBox(height: 12),
              _buildTextField(_categoryController, "Category"),
              SizedBox(height: 12),
              SwitchListTile(
                value: _isNegotiable,
                onChanged: (value) {
                  setState(() => _isNegotiable = value);
                },
                title: Text("Is Negotiable Price?"),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUpdating ? null : _updateProduct,
                child: Text(_isUpdating ? "Updating..." : "Update Product"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) =>
          value == null || value.isEmpty ? "Please enter $label" : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}